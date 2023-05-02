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
    public var segmentationResult: [SegmentationIdentifier: Loadable<[ScoredMask], SPError>]

    /// The current on-screen point semantics.
    public var pointSemantics: [String: [PointSemantic]]

    public var segmentedImage: [SegmentationIdentifier: UIImage] = [:]

    public var isShowingDeletingSegmentationAlert: Bool

    public struct Cutout: Equatable {
        public let segmentationIdentifier: SegmentationIdentifier
        public let mask: Mask
        public let croppedImage: UIImage

        public init(
            segmentationIdentifier: SegmentationIdentifier,
            mask: Mask,
            croppedImage: UIImage
        ) {
            self.segmentationIdentifier = segmentationIdentifier
            self.mask = mask
            self.croppedImage = croppedImage
        }
    }

    public var cutouts: [String: [Cutout]]

    public init(
        segmentationResult: [SegmentationIdentifier : Loadable<[ScoredMask], SPError>] = [:],
        pointSemantics: [String: [PointSemantic]] = [:],
        segmentedImage: [SegmentationIdentifier: UIImage] = [:],
        cutouts: [String: [Cutout]] = [:],
        isShowingDeletingSegmentationAlert: Bool = false
    ) {
        self.segmentationResult = segmentationResult
        self.pointSemantics = pointSemantics
        self.segmentedImage = segmentedImage
        self.cutouts = cutouts
        self.isShowingDeletingSegmentationAlert = isShowingDeletingSegmentationAlert
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
            pointSemantics: model.pointSemantics[fileName] ?? []
        )
    }

    public var currentPointSemantics: [PointSemantic] {
        get {
            model.pointSemantics[fileName] ?? []
        }
        set {
            model.pointSemantics[fileName] = newValue
        }
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
    case undoPointSemantic(fileName: String)
    case addPointSemantic(PointSemantic, fileName: String)
    case discardSegmentedImage(SegmentationIdentifier)
    case dismissSegmentation
    case requestSegmentation(
        SegmentationIdentifier,
        accessToken: String,
        sourceImage: UIImage
    )
    case didCompleteSegmentation(
        Loadable<[ScoredMask], SPError>,
        segmentedImage: UIImage?,
        segID: SegmentationIdentifier
    )
    case setIsShowingDeletingSegmentationAlert(Bool)
}
