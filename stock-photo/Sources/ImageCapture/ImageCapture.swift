import AVFoundation
import UIKit
import ComposableArchitecture
import Dispatch
import ImageSegmentationClient

public struct ImageCapture: ReducerProtocol, Sendable {
    public struct State: Equatable {
        public var accessToken: String?
        public var capturedImage: CapturedImage?
        public var finalImage: UIImage?
        public var segmentationMask: CVPixelBuffer?

        public init(
            accessToken: String? = nil,
            capturedImage: CapturedImage? = nil,
            finalImage: UIImage? = nil,
            segmentationMask: CVPixelBuffer? = nil
        ) {
            self.accessToken = accessToken
            self.capturedImage = capturedImage
            self.finalImage = finalImage
            self.segmentationMask = segmentationMask
        }
    }

    public enum Action: Equatable {
        case didFinishProcessingPhoto(image: UIImage, depthData: AVDepthData?)
        case clearCapturedImage
        case segmentedImage(TaskResult<ImageSegmentationResponse>)
    }

    @Dependency(\.imageSegmentationClient) var imageSegmentationClient

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .didFinishProcessingPhoto(image: let image, depthData: let depthData):
                state.capturedImage = CapturedImage(
                    id: UUID(),
                    image: image,
                    depthData: depthData
                )
                return .task {
                    .segmentedImage(
                        await TaskResult {
                            try await imageSegmentationClient.segment(
                                ImageSegmentationRequest(
                                    image: image,
                                    requestedContents: [.finalImage, .rawMask]
                                )
                            )
                        }
                    )
                }
            case .clearCapturedImage:
                state.capturedImage = nil
                return .none
            case .segmentedImage(let response):
                switch response {
                case .success(let imageSegmentationResponse):
                    state.finalImage = imageSegmentationResponse.finalImage
                    state.segmentationMask = imageSegmentationResponse.rawMask
                case .failure(let imageSegmentationError):
                    break
                }
                return .none
            }
        }
    }
}
