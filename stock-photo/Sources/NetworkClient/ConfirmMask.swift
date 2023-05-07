public struct ConfirmMaskRequest: Equatable, Encodable {
    public let accessToken: String
    public let imageID: Int
    public let maskID: Int

    public init(
        accessToken: String,
        imageID: Int,
        maskID: Int
    ) {
        self.accessToken = accessToken
        self.imageID = imageID
        self.maskID = maskID
    }

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
        case maskID = "mask_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageID, forKey: .imageID)
        try container.encode(maskID, forKey: .maskID)
    }
}

public struct ConfirmMaskResponse: Equatable, Decodable {
    public let imageID: Int
    public let maskID: Int

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
        case maskID = "mask_id"
    }
}
