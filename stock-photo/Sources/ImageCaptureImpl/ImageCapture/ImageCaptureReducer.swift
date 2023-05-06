import AVFoundation
import UIKit
import ComposableArchitecture
import Dispatch
import ImageCapture

public struct ImageCapture: ReducerProtocol, Sendable {
    public init() {}

    public var body: some ReducerProtocol<ImageCaptureState, ImageCaptureAction> {
        Reduce { state, action in
            switch action {
            case .didCaptureImage(let capturedImage):
                state.capturedImage = capturedImage
                return .none
            case .postCapture(let postCaptureAction):
                switch postCaptureAction {
                case .retakeImage:
                    state.capturedImage = nil
                    return .send(.dismissPostImageCapture)
                case .uploadImage:
                    return .none
                }
            case .dismissPostImageCapture:
                // Dismissal of navigation stack is handled by App
                return .none
            }
        }
    }
}
