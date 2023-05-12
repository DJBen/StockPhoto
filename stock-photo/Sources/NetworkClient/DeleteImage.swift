import StockPhotoFoundation

public struct DeleteImageRequest: Equatable, Encodable {
    public let account: Account
    public let imageID: Int
    public let isSoftDelete: Bool

    public init(
        account: Account,
        imageID: Int,
        isSoftDelete: Bool = false
    ) {
        self.account = account
        self.imageID = imageID
        self.isSoftDelete = isSoftDelete
    }

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
        case isSoftDelete = "is_soft_delete"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageID, forKey: .imageID)
        try container.encode(isSoftDelete, forKey: .isSoftDelete)
    }
}

public struct DeleteImageResponse: Decodable {
    public let imageID: Int

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.imageID = try container.decode(Int.self, forKey: .imageID)
    }
}
