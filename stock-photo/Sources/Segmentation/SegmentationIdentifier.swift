import StockPhotoFoundation

public struct SegmentationIdentifier: Sendable, Equatable, Hashable {
    public let imageID: Int
    public let pointSemantics: [PointSemantic]

    public init(
        imageID: Int,
        pointSemantics: [PointSemantic]
    ) {
        self.imageID = imageID
        self.pointSemantics = pointSemantics
    } 
}

extension AppliedMask {
    public var segID: SegmentationIdentifier {
        SegmentationIdentifier(imageID: imageID, pointSemantics: pointSemantics)
    }
}
