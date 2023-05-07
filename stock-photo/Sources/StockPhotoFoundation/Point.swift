import Foundation

public struct Point: Sendable, Equatable, Codable, Hashable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.x = try container.decode(Int.self)
        self.y = try container.decode(Int.self)
    }

    public func distance(to point: Point) -> Float {
        return sqrtf(Float((x - point.x) * (x - point.x) + (y - point.y) * (y - point.y)))
    }
}

public enum PointLabel: Int, Sendable, Equatable, Decodable, Hashable {
    case foreground = 1
    case background = 0

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(Int.self))!
    }
}

public struct PointSemantic: Sendable, Equatable, Hashable, Identifiable {
    public let point: Point
    public let label: PointLabel

    public var id: String {
        "(\(point.x), \(point.y))_\(label)"
    }

    public init(
        point: Point,
        label: PointLabel
    ) {
        self.point = point
        self.label = label
    }
}
