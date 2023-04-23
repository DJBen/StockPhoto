import AuthenticationServices
import ComposableArchitecture
import CustomDump
import Dispatch
import KeychainAccess
import ImageCaptureCore
import NetworkClient

public struct Login: ReducerProtocol, Sendable {
    enum AuthorizationResult {
        case completed(ASAuthorizationAppleIDCredential, controller: ASAuthorizationController)
        case errored(error: Error, controller: ASAuthorizationController)
    }

    public struct State: Equatable {
        var accessToken: String?
        var userID: String?
        var alert: AlertState<Action>?

        public init() {
        }

        public static func == (lhs: Login.State, rhs: Login.State) -> Bool {
            return lhs.userID == rhs.userID &&
            (lhs.alert != nil) == (rhs.alert != nil)
        }
    }

    public enum Action: Equatable {
        case checkExistingAccessToken
        case didObtainCredentialFromGoogle(GoogleCredentials)
        case didObtainCredentialFromApple(ASAuthorizationAppleIDCredential)
        case didFailLogin(Error)
        case didAuthenticate(accessToken: String, userID: String)

        /// The credential is not found in the keychain. Present login screen normally.
        case didNotFindAccessToken

        case dismissErrorAlert

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.checkExistingAccessToken, .checkExistingAccessToken),
                 (.didObtainCredentialFromApple, .didObtainCredentialFromApple),
                 (.didFailLogin, .didFailLogin),
                 (.didNotFindAccessToken, .didNotFindAccessToken),
                 (.dismissErrorAlert, .dismissErrorAlert):
                return true
            case (.didAuthenticate(let lhsAccessToken, let lhsUserID), .didAuthenticate(let rhsAccessToken, let rhsUserID)):
                return lhsAccessToken == rhsAccessToken && lhsUserID == rhsUserID
            case (.didObtainCredentialFromGoogle(let lhsCredentials), .didObtainCredentialFromGoogle(let rhsCredentials)):
                return lhsCredentials == rhsCredentials
            default:
                return false
            }
        }
    }

    public init() {}

    @Dependency(\.keychain) var keychain
    @Dependency(\.networkClient) var networkClient

    private let accessTokenKey = "session-key"

    private func extractSubFromJWT(_ jwtToken: String) throws -> String {
        func constructError(_ localizedDescription: String) -> Error {
            NSError(
                domain: "JWTToken",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: localizedDescription
                ]
            )
        }

        let tokenComponents = jwtToken.components(separatedBy: ".")

        guard tokenComponents.count == 3 else {
            throw constructError("Invalid JWT token")
        }

        let payloadBase64Url = tokenComponents[1]
        let payloadBase64 = payloadBase64Url.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let missingPadding = payloadBase64.count % 4
        let padding = missingPadding > 0 ? String(repeating: "=", count: 4 - missingPadding) : ""

        guard let payloadData = Data(base64Encoded: payloadBase64 + padding) else {
            throw constructError("Invalid base64 encoding")
        }

        if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any], let sub = json["sub"] as? String {
            return sub
        } else {
            throw constructError("User not found in JWT token")
        }
    }

    public var body: some ReducerProtocol<State, Action> {
        // Authentication steps:
        // 1. Check if there is existing access token from keychain.
        //   a. Access token not expired, use it; go to 4.
        //   b. Access token expired, delete it, go to 2.
        // 2. Obtain a Google or Apple authorization code using the login buttons.
        // 3. Authenticate with either login/google or login/apple endpoints of
        // our service, and exchange a access token. Save access token to keychain.
        // 4. Log in with the access token.

        Reduce { state, action in
            switch action {
            case .checkExistingAccessToken:
                return .task {
                    if let accessToken = keychain[accessTokenKey] {
                        let userID = try! extractSubFromJWT(accessToken)
                        return .didAuthenticate(accessToken: accessToken, userID: userID)
                    } else {
                        return .didNotFindAccessToken
                    }
                }
            case .didFailLogin(let error):
                state.alert = AlertState(title: {
                    TextState(error.localizedDescription)
                })
                return .none
            case .didObtainCredentialFromGoogle(let credentials):
                return .task(
                    operation: {
                        let response = try await networkClient.authenticateGoogle(
                            AuthenticateGoogleRequest(
                                code: credentials.code,
                                email: credentials.email,
                                givenName: credentials.givenName,
                                familyName: credentials.familyName
                            )
                        )
                        keychain[accessTokenKey] = response.accessToken
                        let userID = try extractSubFromJWT(response.accessToken)
                        return .didAuthenticate(accessToken: response.accessToken, userID: userID)
                    },
                    catch: { error in
                        return .didFailLogin(error)
                    }
                )
            case .didObtainCredentialFromApple(let credential):
                return .task(
                    operation: {
                        guard let code = credential.authorizationCode else {
                            return .didFailLogin(
                                NSError(
                                    domain: "ASAuthorizationAppleIDCredential",
                                    code: 501,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Apple credential does not contain authorization code"
                                    ]
                                )
                            )
                        }
                        let response = try await networkClient.authenticateApple(
                            AuthenticateAppleRequest(
                                code: String(data: code, encoding: .utf8)!,
                                email: credential.email,
                                fullName: credential.fullName
                            )
                        )
                        keychain[accessTokenKey] = response.accessToken
                        let userID = try extractSubFromJWT(response.accessToken)
                        return .didAuthenticate(accessToken: response.accessToken, userID: userID)
                    },
                    catch: { error in
                        return .didFailLogin(error)
                    }
                )
            case .didAuthenticate(let accessToken, let userID):
                state.accessToken = accessToken
                state.userID = userID
                return .none
            case .didNotFindAccessToken:
                // No credentials find, present the login view normally
                return .none
            case .dismissErrorAlert:
                state.alert = nil
                return .none
            }
        }
    }
}

extension ASAuthorizationAppleIDCredential: CustomDumpReflectable {
    public var customDumpMirror: Mirror {
        .init(
            self,
            children: [
                "user": user,
                "state": state as Any,
                "authorizedScopes": authorizedScopes,
                "authorizationCode": authorizationCode as Any,
                "identityToken": identityToken as Any,
                "email": email as Any,
                "fullName": fullName as Any,
                "realUserStatus": realUserStatus
            ],
            displayStyle: .struct
        )
    }
}
