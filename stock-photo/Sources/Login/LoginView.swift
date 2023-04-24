import ComposableArchitecture
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

public struct LoginView: View {
    let store: StoreOf<Login>

    public init(store: StoreOf<Login>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 16) {
                Spacer()

                GoogleSignInButton(
                    disabled: viewStore.isAuthenticating
                ) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first, let rootViewController = window.rootViewController {
                        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signinResult, error in
                            if let signinResult = signinResult, let authCode = signinResult.serverAuthCode {
                                viewStore.send(
                                    .didObtainCredentialFromGoogle(
                                        GoogleCredentials(
                                            code: authCode,
                                            email: signinResult.user.profile?.email,
                                            givenName: signinResult.user.profile?.givenName,
                                            familyName: signinResult.user.profile?.familyName
                                        )
                                    )
                                )
                            } else if let error = error {
                                viewStore.send(.didFailLogin(error))
                            }
                        }
                    }
                }
                .frame(height: 60)
                .padding(.horizontal, 24)

                SignInWithAppleButton { completion in
                    switch completion {
                    case .completed(let credential, controller: _):
                        viewStore.send(.didObtainCredentialFromApple(credential))
                    case .errored(error: let error, controller: _):
                        viewStore.send(.didFailLogin(error))
                    }
                }
                .disabled(viewStore.isAuthenticating)
                .frame(height: 60)
                .padding(.horizontal, 24)
            }
            .onAppear {
                viewStore.send(.checkExistingAccessToken)
            }
            .alert(store.scope(state: \.alert), dismiss: .dismissErrorAlert)
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(
            store: Store(
                initialState: Login.State(),
                reducer: EmptyReducer()
            )
        )
    }
}
