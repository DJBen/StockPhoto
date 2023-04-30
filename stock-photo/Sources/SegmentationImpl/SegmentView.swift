import ComposableArchitecture
import ImageViewer
import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI

public struct SegmentationView: View {
    let store: StoreOf<Segmentation>

    public init(store: StoreOf<Segmentation>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            ImageViewerView(
                image: viewStore.image,
                onTap: { x, y in
                    print("{\(x), \(y)}")
                }
            )
            .onDisappear {
                viewStore.send(.dismissSegmentation)
            }
        }
    }
}
