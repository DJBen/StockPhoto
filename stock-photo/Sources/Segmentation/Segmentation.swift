import Foundation
import StockPhotoFoundation
import UIKit

/// Store the segmentation related data model.
///
/// Note this data model should not have derived properties from other modules (like login credentials).
public struct SegmentationModel: Equatable, Sendable {
    /// The segment masks generated from the request identified by `SegmentationIdentifier`.
    ///
    /// Multiple masks may be generated from the same image, if their point semantics are different.
    public var segmentationResults: [SegmentationIdentifier: Loadable<SegmentationResult, SPError>]

    /// The current on-screen point semantics.
    public var pointSemantics: [Int: [PointSemantic]]

    public var segmentedImage: [SegmentationIdentifier: UIImage]

    public var segmentationResultConfirmations: [SegmentationIdentifier: Loadable<Int, SPError>]

    public var isShowingDeletingSegmentationAlert: Bool

    public init(
        segmentationResults: [SegmentationIdentifier: Loadable<SegmentationResult, SPError>] = [:],
        pointSemantics: [Int: [PointSemantic]] = [:],
        segmentedImage: [SegmentationIdentifier: UIImage] = [:],
        segmentationResultConfirmations: [SegmentationIdentifier: Loadable<Int, SPError>] = [:],
        isShowingDeletingSegmentationAlert: Bool = false
    ) {
        self.segmentationResults = segmentationResults
        self.pointSemantics = pointSemantics
        self.segmentedImage = segmentedImage
        self.segmentationResultConfirmations = segmentationResultConfirmations
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
    public var project: Project
    public var image: UIImage

    public var isSegmenting: Bool {
        switch model.segmentationResults[segID] {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var isConfirmingSegmentation: Bool {
        switch model.segmentationResultConfirmations[segID] {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var segID: SegmentationIdentifier {
        return SegmentationIdentifier(
            imageID: project.id,
            pointSemantics: model.pointSemantics[project.id] ?? []
        )
    }

    public var currentPointSemantics: [PointSemantic] {
        get {
            model.pointSemantics[project.id] ?? []
        }
        set {
            model.pointSemantics[project.id] = newValue
        }
    }

    public init(
        model: SegmentationModel,
        accessToken: String?,
        project: Project,
        image: UIImage
    ) {
        self.model = model
        self.accessToken = accessToken
        self.project = project
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
    case confirmSegmentationResult(
        maskID: Int,
        segID: SegmentationIdentifier,
        accessToken: String
    )
    case confirmedSegmentationResult(
        Loadable<Int, SPError>,
        segID: SegmentationIdentifier
    )
}
