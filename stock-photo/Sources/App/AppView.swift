import ComposableArchitecture
import Login
import Home
import HomeImpl
import ImageCapture
import ImageCaptureImpl
import Segmentation
import SegmentationImpl
import SwiftUI

public struct AppView: View {
    let store: StoreOf<StockPhoto>

    public init(store: StoreOf<StockPhoto>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            NavigationStack(
                path: viewStore.binding(
                    get: \.destinations,
                    send: StockPhoto.Action.navigationChanged
                )
            ) {
//                ImageCaptureView(
//                    store: store.scope(
//                        state: \.imageCapture,
//                        action: StockPhoto.Action.imageCapture
//                    )
//                )
                HomeView<
                    Segmentation,
                    SegmentationView
                >(
                    store: store.scope(
                        state: HomeState.project,
                        action: StockPhoto.Action.home
                    ),
                    segmentViewBuilder: SegmentationView.init
                )
                .fullScreenCover(
                    isPresented: viewStore.binding(
                        get: { $0.login.isShowingLoginSheet },
                        send: { StockPhoto.Action.login(.setLoginSheetPresented($0)) }
                    )
                ) {
                    LoginView(
                        store: store.scope(
                            state: \.login,
                            action: StockPhoto.Action.login
                        )
                    )
                }
            }
        }
    }
}
