public struct SegmentationIdentifier: Sendable, Equatable, Hashable {
    public let fileName: String
    public let pointSemantics: [PointSemantic]

    public init(
        fileName: String,
        pointSemantics: [PointSemantic]
    ) {
        self.fileName = fileName
        self.pointSemantics = pointSemantics
    } 
}
