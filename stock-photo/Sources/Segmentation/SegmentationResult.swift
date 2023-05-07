import StockPhotoFoundation

public struct SegmentationResult: Sendable, Identifiable, Equatable {
    public let id: Int
    public let mask: Mask

    public init(id: Int, mask: Mask) {
        self.id = id
        self.mask = mask
    }
}
