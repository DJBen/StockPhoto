import Foundation

public struct UploadImageRequest: Codable {
    public let accessToken: String
    public let image: Data
    public let mimeType: String
    public let overwrite: Bool

    public init(
        accessToken: String,
        image: Data,
        mimeType: String,
        overwrite: Bool
    ) {
        self.accessToken = accessToken
        self.image = image
        self.mimeType = mimeType
        self.overwrite = overwrite
    }
}

public struct UploadImageResponse: Equatable, Codable, Sendable {
    public let imageID: Int

    public init(imageID: Int) {
        self.imageID = imageID
    }
}

public enum UploadFileUpdate: Equatable, Sendable {
    case inProgress(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    case completed(UploadImageResponse)
}
