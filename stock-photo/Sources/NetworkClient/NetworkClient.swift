import Dependencies

public struct NetworkClient: Sendable {
    public var authenticateGoogle: @Sendable (AuthenticateGoogleRequest) async throws -> AuthenticateGoogleResponse
    public var authenticateApple: @Sendable (AuthenticateAppleRequest) async throws -> AuthenticateAppleResponse

    public init(
        authenticateGoogle: @escaping @Sendable (AuthenticateGoogleRequest) async throws -> AuthenticateGoogleResponse,
        authenticateApple: @escaping @Sendable (AuthenticateAppleRequest) async throws -> AuthenticateAppleResponse
    ) {
        self.authenticateGoogle = authenticateGoogle
        self.authenticateApple = authenticateApple
    }
}

extension NetworkClient: TestDependencyKey {
    public static var testValue = NetworkClient(
        authenticateGoogle: { _ in
            AuthenticateGoogleResponse(accessToken: "", tokenType: "bearer")
        },
        authenticateApple: { _ in
            AuthenticateAppleResponse(accessToken: "", tokenType: "bearer")
        }
    )
}

extension DependencyValues {
    public var networkClient: NetworkClient {
        get { self[NetworkClient.self] }
        set { self[NetworkClient.self] = newValue }
    }
}
