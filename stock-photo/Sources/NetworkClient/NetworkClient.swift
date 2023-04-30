import UIKit

public protocol NetworkClient: Sendable {
    func authenticateGoogle(_ request: AuthenticateGoogleRequest) async throws -> AuthenticateGoogleResponse
    func authenticateApple(_ request: AuthenticateAppleRequest) async throws -> AuthenticateAppleResponse
    func uploadImage(_ request: UploadImageRequest) async -> AsyncThrowingStream<UploadFileUpdate, Error>
    func listImageProjects(_ request: ListImageProjectsRequest) async throws -> ListImageProjectsResponse
    func fetchImage(_ request: FetchImageRequest) async throws -> UIImage
    func segment(_ request: SegmentRequest) async throws -> SegmentResponse
}
