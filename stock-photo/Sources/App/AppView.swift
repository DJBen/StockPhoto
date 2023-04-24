import ComposableArchitecture
import Login
import ImageCapture
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
                ImageCaptureView(
                    store: store.scope(
                        state: \.imageCapture,
                        action: StockPhoto.Action.imageCapture
                    )
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

//        SwitchStore(self.store) {
//            CaseLet(state: /StockPhoto.State.imageCapture, action: StockPhoto.Action.imageCapture) { store in
//                ImageCaptureView(store: store)
//            }
//        }
    }
}
