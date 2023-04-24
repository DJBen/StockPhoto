import Foundation

public struct UploadImageRequest: Codable {
    public let accessToken: String
    public let image: Data
    public let fileName: String
    public let overwrite: Bool

    public init(
        accessToken: String,
        image: Data,
        fileName: String,
        overwrite: Bool
    ) {
        self.accessToken = accessToken
        self.image = image
        self.fileName = fileName
        self.overwrite = overwrite
    }
}

public struct UploadImageResponse: Equatable, Codable, Sendable {
    public let fileName: String

    public init(fileName: String) {
        self.fileName = fileName
    }
}

public enum UploadFileUpdate: Equatable, Sendable {
    case inProgress(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    case completed(UploadImageResponse)
}
