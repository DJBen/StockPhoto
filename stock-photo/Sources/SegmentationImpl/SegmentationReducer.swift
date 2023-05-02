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
            case .undoPointSemantic:
                state.pointSemantics.removeLast()
                return .none
            case .addPointSemantic(let pointSemantic):
                state.pointSemantics.append(pointSemantic)
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
                        var segmentedImage: UIImage?
                        if let firstMask = response.masks.first {
                            segmentedImage = sourceImage.croppedImage(
                                using: firstMask.counts
                            )
                        }
                        return .didCompleteSegmentation(
                            .loaded(response.masks),
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
                if let segmentedImage = segmentedImage {
                    state.segmentedImages[segID] = segmentedImage
                }
                return .none
            }
        }
    }
}
