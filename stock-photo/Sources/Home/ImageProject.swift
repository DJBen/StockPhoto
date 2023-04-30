import Foundation

public struct ImageProject: Sendable, Equatable, Identifiable, Decodable, Hashable {
    public var id: String
    public var imageFile: String
    public var thumbnailFile: String?

    public init(
        id: String,
        imageFile: String,
        thumbnailFile: String?
    ) {
        self.id = id
        self.imageFile = imageFile
        self.thumbnailFile = thumbnailFile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.imageFile = try container.decode(String.self, forKey: .imageFile)
        self.thumbnailFile = try container.decodeIfPresent(String.self, forKey: .thumbnailFile)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case imageFile = "image_file"
        case thumbnailFile = "thumbnail_file"
    }
}
