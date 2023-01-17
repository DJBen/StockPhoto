import ComposableArchitecture
import ImageCaptureCore
import SwiftUI

public struct ImageCaptureView: View {
    let store: StoreOf<ImageCapture>

    public init(store: StoreOf<ImageCapture>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            CameraView(
                didFinishProcessingPhoto: { image, depthData in
                    viewStore.send(
                        .didFinishProcessingPhoto(image: image, depthData: depthData)
                    )
                }
            )
            .sheet(
                item: Binding(
                    get: {
                        viewStore.capturedImage
                    },
                    set: { _ in
                        viewStore.send(.clearCapturedImage)
                    }
                ),
                content: { capturedImage in
                    ImageSegmentationDisplayView(capturedImage: capturedImage)
                }
            )
        }
    }
}
