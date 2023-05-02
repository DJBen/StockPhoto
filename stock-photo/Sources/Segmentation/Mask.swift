import CustomDump

public struct Mask: Equatable, Decodable {
    public let size: Size
    public let counts: [Int]
}

@dynamicMemberLookup
public struct ScoredMask: Equatable, Comparable {
    public let mask: Mask
    public let score: Float

    public subscript<Value>(dynamicMember keyPath: KeyPath<Mask, Value>) -> Value {
        self.mask[keyPath: keyPath]
    }

    public init(mask: Mask, score: Float) {
        self.mask = mask
        self.score = score
    }

    public static func <(lhs: ScoredMask, rhs: ScoredMask) -> Bool {
        return lhs.score < rhs.score
    }
}

extension Mask: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        return "{\(size.width) x \(size.height) mask}"
    }
}
