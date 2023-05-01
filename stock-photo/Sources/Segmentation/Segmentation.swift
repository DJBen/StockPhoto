import Foundation
import StockPhotoFoundation
import UIKit

public struct SegmentationState: Equatable {
    public var accessToken: String
    public var fileName: String
    public var image: UIImage
    public var segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>]
    public var afterSegmentationSnapshot: UIImage?

    public init(
        accessToken: String,
        fileName: String,
        image: UIImage,
        segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>],
        afterSegmentationSnapshot: UIImage?
    ) {
        self.accessToken = accessToken
        self.fileName = fileName
        self.image = image
        self.segmentationResult = segmentationResult
        self.afterSegmentationSnapshot = afterSegmentationSnapshot
    }
}

public enum SegmentationAction: Equatable {
    case dismissSegmentation
    case requestSegmentation(SegmentationIdentifier, accessToken: String, snapshot: UIImage?)
    case didCompleteSegmentation(Loadable<[Mask], SPError>, segID: SegmentationIdentifier)
}
