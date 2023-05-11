import Foundation
import StockPhotoFoundation

public struct UploadImageRequest: Encodable, Equatable, Sendable {
    public let id: String
    public let account: Account
    public let image: Data
    public let mimeType: String

    public init(
        id: String,
        account: Account,
        image: Data,
        mimeType: String
    ) {
        self.id = id
        self.account = account
        self.image = image
        self.mimeType = mimeType
    }

    private enum CodingKeys: String, CodingKey {
        case image
        case mimeType = "mime_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image, forKey: .image)
        try container.encode(mimeType, forKey: .mimeType)
    }
}

public struct UploadImageResponse: Equatable, Codable, Sendable {
    public let imageID: Int

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
    }

    public init(imageID: Int) {
        self.imageID = imageID
    }
}
