import AuthenticationServices
import ComposableArchitecture
import CustomDump
import Dispatch
import KeychainAccess
import ImageCapture
import NetworkClient
import StockPhotoFoundation

public struct Login: ReducerProtocol, Sendable {
    enum AuthorizationResult {
        case completed(ASAuthorizationAppleIDCredential, controller: ASAuthorizationController)
        case errored(error: Error, controller: ASAuthorizationController)
    }

    public struct State: Equatable {
        public var isShowingLoginSheet: Bool = true
        public var accessToken: String?
        public var userID: String?
        /// Whether it is calling our backend service to authenticate.
        ///
        /// Signin buttons should be disabled, until either successful or failed result returns.
        public var isAuthenticating: Bool = false
        public var displayingErrors: [SPError] = []

        public init() {}
    }

    public enum Action: Equatable {
        case checkExistingAccessToken
        case didObtainCredentialFromGoogle(GoogleCredentials)
        case didObtainCredentialFromApple(ASAuthorizationAppleIDCredential)
        case didFailLogin(SPError)
        case didAuthenticate(accessToken: String, userID: String)

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
                        return .didAuthenticate(accessToken: accessToken, userID: userID)
                    } else {
                        return .didNotFindAccessToken
                    }
                }
            case .didFailLogin(let error):
                state.displayingErrors.append(error)
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
                        return .didAuthenticate(accessToken: response.accessToken, userID: userID)
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
                        return .didAuthenticate(accessToken: response.accessToken, userID: userID)
                    },
                    catch: { error in
                        return .didFailLogin(SPError.catch(error))
                    }
                )
            case .didAuthenticate(let accessToken, let userID):
                state.accessToken = accessToken
                state.userID = userID
                state.isShowingLoginSheet = false
                return .none
            case .didNotFindAccessToken:
                // No credentials find, present the login view normally
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
