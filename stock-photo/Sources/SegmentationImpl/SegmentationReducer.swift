import ComposableArchitecture
import NetworkClient
import Segmentation
import StockPhotoFoundation
import SwiftUI

public struct Segmentation: ReducerProtocol, Sendable {
    private var networkClient: NetworkClient

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    public var body: some ReducerProtocol<SegmentationState, SegmentationAction> {
        Reduce { state, action in
            switch action {
            case .undoPointSemantic(let imageID):
                if let pointSemantics = state.pointSemantics[imageID], !pointSemantics.isEmpty {
                    state.pointSemantics[imageID]?.removeLast()
                }
                return .none
            case .addPointSemantic(let pointSemantic, let imageID):
                if state.pointSemantics[imageID] == nil {
                    state.pointSemantics[imageID] = []
                }
                state.pointSemantics[imageID]?.append(pointSemantic)
                return .none
            case .discardSegmentedImage(let segID):
                state.segmentedImage[segID] = nil
                return .none
            case .dismissSegmentation:
                // Handled by the parent
                return .none
            case .requestSegmentation(
                let segID,
                let accessToken,
                let sourceImage
            ):
                state.segmentationResults[segID] = .loading

                return .task(
                    operation: {
                        let response = try await networkClient.segment(
                            SegmentRequest(
                                accessToken: accessToken,
                                imageID: segID.imageID,
                                pointSemantics: segID.pointSemantics
                            )
                        )
                        let segmentationResult = SegmentationResult(
                            id: response.id,
                            mask: response.mask
                        )
                        let segmentedImage = sourceImage.croppedImage(
                            using: segmentationResult.mask.counts
                        )
                        return .didCompleteSegmentation(
                            .loaded(segmentationResult),
                            segmentedImage: segmentedImage,
                            segID: segID
                        )
                    },
                    catch: { error in
                        return .didCompleteSegmentation(
                            .failed(SPError.catch(error)),
                            segmentedImage: nil,
                            segID: segID
                        )
                    }
                )
                .cancellable(id: segID)
            case .didCompleteSegmentation(let masksLoadable, let segmentedImage, let segID):
                state.segmentationResults[segID] = masksLoadable
                state.segmentedImage[segID] = segmentedImage
                return .none
            case .setIsShowingDeletingSegmentationAlert(let isShowing):
                state.isShowingDeletingSegmentationAlert = isShowing
                return .none
            }
        }
    }
}
