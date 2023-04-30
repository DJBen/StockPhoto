import Foundation
import StockPhotoFoundation
import UIKit

public struct SegmentationState: Equatable {
    public let fileID: String
    public let image: UIImage
    public let segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>]

    public init(
        fileID: String,
        image: UIImage,
        segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>]
    ) {
        self.fileID = fileID
        self.image = image
        self.segmentationResult = segmentationResult
    }
}

public enum SegmentationAction: Equatable {
    case dismissSegmentation
    case requestSegmentation(SegmentationIdentifier)
    case didCompleteSegmentation(Loadable<[Mask], SPError>, segID: SegmentationIdentifier)
}
