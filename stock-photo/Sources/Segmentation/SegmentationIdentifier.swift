public struct SegmentationIdentifier: Equatable, Hashable {
    public let fileName: String
    public let pointSemantic: PointSemantic

    public init(
        fileName: String,
        pointSemantic: PointSemantic
    ) {
        self.fileName = fileName
        self.pointSemantic = pointSemantic
    } 
}