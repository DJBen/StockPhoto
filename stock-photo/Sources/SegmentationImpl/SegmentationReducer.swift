import ComposableArchitecture
import NetworkClient
import Segmentation
import StockPhotoFoundation

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
            case .requestSegmentation(let segID):
                return .none
            case .didCompleteSegmentation(let masksLoadable, let segID):
                return .none
            }
        }
    }
}
