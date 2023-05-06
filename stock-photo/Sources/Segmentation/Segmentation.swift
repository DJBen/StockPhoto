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
    public var segmentationResults: [SegmentationIdentifier: Loadable<SegmentationResult, SPError>]

    /// The current on-screen point semantics.
    public var pointSemantics: [Int: [PointSemantic]]

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
        segmentationResults: [SegmentationIdentifier: Loadable<SegmentationResult, SPError>] = [:],
        pointSemantics: [Int: [PointSemantic]] = [:],
        segmentedImage: [SegmentationIdentifier: UIImage] = [:],
        cutouts: [String: [Cutout]] = [:],
        isShowingDeletingSegmentationAlert: Bool = false
    ) {
        self.segmentationResults = segmentationResults
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

    public var accessToken: String?
    public var imageProject: ImageProject
    public var image: UIImage

    public var isSegmenting: Bool {
        switch model.segmentationResults[segID] {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var segID: SegmentationIdentifier {
        return SegmentationIdentifier(
            imageID: imageProject.id,
            pointSemantics: model.pointSemantics[imageProject.id] ?? []
        )
    }

    public var currentPointSemantics: [PointSemantic] {
        get {
            model.pointSemantics[imageProject.id] ?? []
        }
        set {
            model.pointSemantics[imageProject.id] = newValue
        }
    }

    public init(
        model: SegmentationModel,
        accessToken: String?,
        imageProject: ImageProject,
        image: UIImage
    ) {
        self.model = model
        self.accessToken = accessToken
        self.imageProject = imageProject
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
    case undoPointSemantic(imageID: Int)
    case addPointSemantic(PointSemantic, imageID: Int)
    case discardSegmentedImage(SegmentationIdentifier)
    case dismissSegmentation
    case requestSegmentation(
        SegmentationIdentifier,
        accessToken: String,
        sourceImage: UIImage
    )
    case didCompleteSegmentation(
        Loadable<SegmentationResult, SPError>,
        segmentedImage: UIImage?,
        segID: SegmentationIdentifier
    )
    case setIsShowingDeletingSegmentationAlert(Bool)
}
