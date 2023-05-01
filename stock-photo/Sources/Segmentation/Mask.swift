import CustomDump

public struct Mask: Equatable, Decodable {
    public let size: Size
    public let counts: [Int]
}

extension Mask: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        return "{\(size.width) x \(size.height) mask}"
    }
}
