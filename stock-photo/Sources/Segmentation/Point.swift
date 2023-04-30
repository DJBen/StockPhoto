import Foundation

public struct Point: Equatable, Encodable, Hashable {
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
}

public enum PointLabel: Int, Equatable, Hashable {
    case foreground = 1
    case background = 0
}

public struct PointSemantic: Equatable, Hashable {
    public let point: Point
    public let label: PointLabel

    public init(
        point: Point,
        label: PointLabel
    ) {
        self.point = point
        self.label = label
    }
}
