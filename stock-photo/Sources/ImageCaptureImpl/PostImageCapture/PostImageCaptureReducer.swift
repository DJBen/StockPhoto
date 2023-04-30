import ComposableArchitecture
import ImageCapture

public struct PostImageCapture: ReducerProtocol, Sendable {
    public var body: some ReducerProtocol<PostImageCaptureState, PostImageCaptureAction> {
        Reduce { state, action in
            switch action {
            case .retakeImage:
                // Dismissal handled by the parent
                return .none
            case .uploadImage:
                return .none
            }
        }
    }
}
