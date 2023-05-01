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
            case .dismissSegmentation:
                // Handled by the parent
                return .none
            case .requestSegmentation(let segID, let accessToken, let snapshot):
                state.segmentationResult[segID] = .loading
                state.afterSegmentationSnapshot = snapshot

                return .task(
                    operation: {
                        let response = try await networkClient.segment(
                            SegmentRequest(
                                accessToken: accessToken,
                                fileName: segID.fileName,
                                pointSemantics: segID.pointSemantics
                            )
                        )
                        return .didCompleteSegmentation(.loaded(response.masks), segID: segID)
                    },
                    catch: { error in
                        return .didCompleteSegmentation(.failed(SPError.catch(error)), segID: segID)
                    }
                )
                .cancellable(id: segID)
            case .didCompleteSegmentation(let masksLoadable, let segID):
                state.segmentationResult[segID] = masksLoadable
                state.afterSegmentationSnapshot = nil
                return .none
            }
        }
    }
}
