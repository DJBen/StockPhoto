public struct Size: Equatable, Decodable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    private enum CodingKeys: CodingKey {
        case width
        case height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try container.decode(Int.self, forKey: .width)
        self.height = try container.decode(Int.self, forKey: .height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
}
