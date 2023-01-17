import AVFoundation
import UIKit
import ComposableArchitecture
import Dispatch
import ImageSegmentationClient

public struct CapturedImage: Equatable, Identifiable {
    public var id: UUID
    public var image: UIImage
    public var depthData: AVDepthData?

    public init(id: UUID, image: UIImage, depthData: AVDepthData? = nil) {
        self.id = id
        self.image = image
        self.depthData = depthData
    }
}

public struct ImageCapture: ReducerProtocol {
    public struct State: Equatable {
        public var capturedImage: CapturedImage?

        public init(capturedImage: CapturedImage? = nil) {
            self.capturedImage = capturedImage
        }
    }

    public enum Action: Equatable {
        case didFinishProcessingPhoto(image: UIImage, depthData: AVDepthData?)
        case clearCapturedImage
    }

    @Dependency(\.imageSegmentationClient) var imageSegmentationClient

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .didFinishProcessingPhoto(image: let image, depthData: let depthData):
                state.capturedImage = CapturedImage(id: UUID(), image: image, depthData: depthData)
                return .none
            case .clearCapturedImage:
                state.capturedImage = nil
                return .none
            }
        }
    }
}
