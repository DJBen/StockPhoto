public struct ImageDescriptor: Sendable, Equatable, Identifiable, Decodable, Hashable {
    public var id: Int

    public init(
        id: Int
    ) {
        self.id = id
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
    }

    private enum CodingKeys: String, CodingKey {
        case id
    }
}
