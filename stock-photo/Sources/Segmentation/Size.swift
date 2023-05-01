public struct Size: Equatable, Decodable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.width = try container.decode(Int.self)
        self.height = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
}
