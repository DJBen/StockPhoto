import Foundation
import StockPhotoFoundation

public struct UploadImageRequest: Encodable, Equatable, Sendable {
    public let account: Account
    public let image: Data
    public let mimeType: String
    public let overwrite: Bool

    public init(
        account: Account,
        image: Data,
        mimeType: String,
        overwrite: Bool
    ) {
        self.account = account
        self.image = image
        self.mimeType = mimeType
        self.overwrite = overwrite
    }

    private enum CodingKeys: String, CodingKey {
        case image
        case mimeType = "mime_type"
        case overwrite
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image, forKey: .image)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(overwrite, forKey: .overwrite)
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
