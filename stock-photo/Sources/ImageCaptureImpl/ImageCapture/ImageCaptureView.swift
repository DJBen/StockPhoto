import ComposableArchitecture
import Dependencies
import ImageCapture
import Navigation
import SwiftUI

public struct ImageCaptureView: View {
    let store: StoreOf<ImageCapture>

    @Dependency(\.uuid) var uuid

    public init(store: StoreOf<ImageCapture>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            CameraView(
                shouldRunCameraSession: viewStore.capturedImage == nil,
                didFinishProcessingPhoto: { image, depthData in
                    viewStore.send(
                        .didCaptureImage(
                            CapturedImage(
                                id: uuid(),
                                image: image,
                                depthData: depthData
                            )
                        )
                    )
                }
            )
            .ignoresSafeArea()
            .navigationDestination(for: StockPhotoDestination.self) { destination in
                switch destination {
                case .postImageCapture(let capturedImage):
                    PostImageCaptureView(
                        store: store.scope(
                            state: { state in
                                PostImageCapture.State(
                                    capturedImage: capturedImage,
                                    buttonText: .retake
                                )
                            },
                            action: ImageCaptureAction.postCapture
                        )
                    )
                    .toolbar(.hidden, for: .navigationBar)
                case .selectedImageProject(_):
                    EmptyView()
                }
            }
        }
    }
}
