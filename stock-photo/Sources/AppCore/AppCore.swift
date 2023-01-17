import ComposableArchitecture
import Dispatch
import ImageCaptureCore

public struct StockPhoto: ReducerProtocol {
    public enum State: Equatable {
        case imageCapture(ImageCapture.State)

        public init() {
            self = .imageCapture(ImageCapture.State())
        }
    }

    public enum Action: Equatable {
        case imageCapture(ImageCapture.Action)
    }

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .imageCapture(_):
                return .none
            }
        }
        .ifCaseLet(/State.imageCapture, action: /Action.imageCapture) {
            ImageCapture()
        }
    }
}
