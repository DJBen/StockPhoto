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
            case .undoPointSemantic(let fileName):
                if let pointSemantics = state.pointSemantics[fileName], !pointSemantics.isEmpty {
                    state.pointSemantics[fileName]?.removeLast()
                }
                return .none
            case .addPointSemantic(let pointSemantic, let fileName):
                if state.pointSemantics[fileName] == nil {
                    state.pointSemantics[fileName] = []
                }
                state.pointSemantics[fileName]?.append(pointSemantic)
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
                state.segmentationResult[segID] = .loading

                return .task(
                    operation: {
                        let response = try await networkClient.segment(
                            SegmentRequest(
                                accessToken: accessToken,
                                fileName: segID.fileName,
                                pointSemantics: segID.pointSemantics
                            )
                        )
                        let scoredMasks = zip(response.masks, response.scores).map {
                            ScoredMask(mask: $0, score: $1)
                        }
                        let segmentedImage = scoredMasks.max(
                        )
                        .flatMap { mask in
                            sourceImage.croppedImage(
                                using: mask.counts
                            )
                        }
                        return .didCompleteSegmentation(
                            .loaded(scoredMasks),
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
                state.segmentationResult[segID] = masksLoadable
                state.segmentedImage[segID] = segmentedImage
                return .none
            case .setIsShowingDeletingSegmentationAlert(let isShowing):
                state.isShowingDeletingSegmentationAlert = isShowing
                return .none
            }
        }
    }
}
