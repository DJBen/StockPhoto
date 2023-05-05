import Foundation

public struct ImageProject: Sendable, Equatable, Identifiable, Decodable, Hashable {
    public var id: Int
    public var fileName: String

    public init(
        id: Int,
        fileName: String
    ) {
        self.id = id
        self.fileName = fileName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file_name"
    }
}
