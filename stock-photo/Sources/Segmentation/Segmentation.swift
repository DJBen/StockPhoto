import Foundation
import StockPhotoFoundation
import UIKit

/// Store the segmentation related data model.
///
/// Note this data model should not have derived properties from other modules (like login credentials).
public struct SegmentationModel: Equatable {
    /// The segment masks generated from the request identified by `SegmentationIdentifier`.
    ///
    /// Multiple masks may be generated from the same image, if their point semantics are different.
    public var segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>]

    public var pointSemantics: [PointSemantic]

    public var segmentedImages: [SegmentationIdentifier: UIImage] = [:]

    public init(
        segmentationResult: [SegmentationIdentifier : Loadable<[Mask], SPError>] = [:],
        pointSemantics: [PointSemantic] = [],
        segmentedImages: [SegmentationIdentifier: UIImage] = [:]
    ) {
        self.segmentationResult = segmentationResult
        self.pointSemantics = pointSemantics
        self.segmentedImages = segmentedImages
    }
}

/// Segmentation state consumed by the reducer and Segmentation view.
///
/// This state may contain necessary properties derived from other modules (like login credentials).
@dynamicMemberLookup
public struct SegmentationState: Equatable {
    public var model: SegmentationModel

    public var accessToken: String
    public var fileName: String
    public var image: UIImage

    public var isSegmenting: Bool {
        switch model.segmentationResult[segID] {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var segID: SegmentationIdentifier {
        return SegmentationIdentifier(
            fileName: fileName,
            pointSemantics: model.pointSemantics
        )
    }

    public init(
        model: SegmentationModel,
        accessToken: String,
        fileName: String,
        image: UIImage
    ) {
        self.model = model
        self.accessToken = accessToken
        self.fileName = fileName
        self.image = image
    }

    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<SegmentationModel, Value>) -> Value {
        get {
            self.model[keyPath: keyPath]
        }
        set {
            self.model[keyPath: keyPath] = newValue
        }
    }
}

public enum SegmentationAction: Equatable {
    case undoPointSemantic
    case addPointSemantic(PointSemantic)
    case dismissSegmentation
    case requestSegmentation(
        SegmentationIdentifier,
        accessToken: String,
        sourceImage: UIImage
    )
    case didCompleteSegmentation(
        Loadable<[Mask], SPError>,
        segmentedImage: UIImage?,
        segID: SegmentationIdentifier
    )
}
