import AuthenticationServices
import ComposableArchitecture
import CustomDump
import Dispatch
import KeychainAccess
import NetworkClient
import StockPhotoFoundation

public struct Login: ReducerProtocol, Sendable {
    enum AuthorizationResult {
        case completed(ASAuthorizationAppleIDCredential, controller: ASAuthorizationController)
        case errored(error: Error, controller: ASAuthorizationController)
    }

    public struct State: Equatable {
        /// Whether to show the login sheet. It shows after the app fails to obtain the access token.
        public var isShowingLoginSheet: Bool = false
        public var account: Account?
        /// Whether it is calling our backend service to authenticate.
        ///
        /// Signin buttons should be disabled, until either successful or failed result returns.
        public var isAuthenticating: Bool = false

        public init() {}
    }

    public enum Action: Equatable {
        case checkExistingAccessToken
        case renderAccessTokenInvalid
        case didObtainCredentialFromGoogle(GoogleCredentials)
        case didObtainCredentialFromApple(ASAuthorizationAppleIDCredential)
        case didFailLogin(SPError)
        case didAuthenticate(Account)
        /// Remove existing saved access token and re-authenticate
        case resetAccessToken
        /// The credential is not found in the keychain. Present login screen normally.
        case didNotFindAccessToken
        case setLoginSheetPresented(Bool)
    }

    @Dependency(\.keychain) var keychain
    @Dependency(\.jwtExtractor) var jwtExtractor
    private var networkClient: NetworkClient
    private let accessTokenKey = "session-key"

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
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
                        let userID = try! jwtExtractor.extractSubFromJWT(accessToken)
                        return .didAuthenticate(
                            Account(accessToken: accessToken, userID: userID)
                        )
                    } else {
                        return .didNotFindAccessToken
                    }
                }
            case .renderAccessTokenInvalid:
                if let account = state.account {
                    let accessToken = account.accessToken
                    if let dotRange = accessToken.range(of: ".", options: .backwards) {
                        let firstPart = accessToken[..<dotRange.lowerBound]
                        let invalidSignature = "invalid_signature"
                        let invalidJwtToken = firstPart + "." + invalidSignature
                        state.account?.accessToken = invalidJwtToken
                        return .fireAndForget {
                            keychain[accessTokenKey] = invalidJwtToken
                        }
                    }
                }
                return .none
            case .didFailLogin(_):
                // Handled by the parent
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
                        let userID = try jwtExtractor.extractSubFromJWT(response.accessToken)
                        return .didAuthenticate(
                            Account(accessToken: response.accessToken, userID: userID)
                        )
                    },
                    catch: { error in
                        return .didFailLogin(SPError.catch(error))
                    }
                )
            case .didObtainCredentialFromApple(let credential):
                return .task(
                    operation: {
                        guard let code = credential.authorizationCode else {
                            return .didFailLogin(
                                .unknownError(
                                    NSError(
                                        domain: "ASAuthorizationAppleIDCredential",
                                        code: 501,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: "Apple credential does not contain authorization code"
                                        ]
                                    )
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
                        let userID = try jwtExtractor.extractSubFromJWT(response.accessToken)
                        return .didAuthenticate(
                            Account(
                                accessToken: response.accessToken,
                                userID: userID
                            )
                        )
                    },
                    catch: { error in
                        return .didFailLogin(SPError.catch(error))
                    }
                )
            case .didAuthenticate(let account):
                state.account = account
                state.isShowingLoginSheet = false
                return .none
            case .resetAccessToken:
                state.account = nil
                return .task {
                    keychain[accessTokenKey] = nil
                    return .didNotFindAccessToken
                }
            case .didNotFindAccessToken:
                // No credentials find, present the login view normally
                state.isShowingLoginSheet = true
                return .none
            case .setLoginSheetPresented(let isPresented):
                state.isShowingLoginSheet = isPresented
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
