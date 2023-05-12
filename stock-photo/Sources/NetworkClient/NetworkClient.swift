import StockPhotoFoundation
import UIKit

public protocol NetworkClient: Sendable {
    // Authentication
    func authenticateGoogle(_ request: AuthenticateGoogleRequest) async throws -> AuthenticateGoogleResponse
    func authenticateApple(_ request: AuthenticateAppleRequest) async throws -> AuthenticateAppleResponse

    // Projects
    func listProjects(_ request: ListProjectsRequest) async throws -> ListProjectsResponse

    // Images
    func fetchImage(_ request: FetchImageRequest) async throws -> UIImage
    func uploadImage(_ request: UploadImageRequest) -> AsyncThrowingStream<UploadFileUpdate, Error>
    func deleteImage(_ request: DeleteImageRequest) async throws -> DeleteImageResponse

    // Segmentation
    func segment(_ request: SegmentRequest) async throws -> SegmentResponse
    func confirmMask(_ request: ConfirmMaskRequest) async throws -> ConfirmMaskResponse
}

public protocol NetworkEndpointAssignable: NSObjectProtocol, Sendable {
    var endpoint: Endpoint { get set }
}
