import AuthenticationServices
import SwiftUI

struct SignInWithAppleButton: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme

    var authorizationResult: (Login.AuthorizationResult) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: colorScheme == .dark ? .white : .black)
        button.addTarget(context.coordinator, action: #selector(AppleSignInCoordinator.handleSignInButtonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> AppleSignInCoordinator {
        return AppleSignInCoordinator(authorizationResult: authorizationResult)
    }
}

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    let authorizationResult: (Login.AuthorizationResult) -> Void

    init(authorizationResult: @escaping (Login.AuthorizationResult) -> Void) {
        self.authorizationResult = authorizationResult
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            fatalError("Sign in with Apple returns non Apple ID credential")
        }
        authorizationResult(.completed(appleIDCredential, controller: controller))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authorizationResult(.errored(error: error, controller: controller))
    }

    @objc func handleSignInButtonTapped() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
}

struct SignInWithAppleButton_Previews: PreviewProvider {
    static var previews: some View {
        SignInWithAppleButton { authResult in }
    }
}
