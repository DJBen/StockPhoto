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
            CameraView()
        }
    }
}
