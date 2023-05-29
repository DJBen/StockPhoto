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
                .alert(
                    store.scope(state: \.alertState),
                    dismiss: .dismissError
                )
                .fullScreenCover(
                    isPresented: viewStore.binding(
                        get: {
                            $0.login.isShowingLoginSheet
                        },
                        send: {
                            StockPhoto.Action.login(.setLoginSheetPresented($0))
                        }
                    )
                ) {
                    LoginView(
                        store: store.scope(
                            state: \.login,
                            action: StockPhoto.Action.login
                        )
                    )
                    #if DEBUG
                    .sheet(
                        isPresented: viewStore.binding(
                            get: {
                                // Showing two sheets at the same time is not allowed
                                // https://nilcoalescing.com/blog/ShowMultipleSheetsAtOnceInSwiftUI/
                                $0.debug.isPresentingDebugSheet
                            },
                            send: {
                                StockPhoto.Action.debug(.setPresentDebugSheet($0))
                            }
                        )
                    ) {
                        DebugView(store: store.scope(state: \.debug, action: StockPhoto.Action.debug))
                    }
                    #endif
                }
                #if DEBUG
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                    viewStore.send(.debug(.setPresentDebugSheet(true)))
                }
                .sheet(
                    isPresented: viewStore.binding(
                        get: {
                            // Showing two sheets at the same time is not allowed
                            // https://nilcoalescing.com/blog/ShowMultipleSheetsAtOnceInSwiftUI/
                            $0.debug.isPresentingDebugSheet && !$0.login.isShowingLoginSheet
                        },
                        send: {
                            StockPhoto.Action.debug(.setPresentDebugSheet($0))
                        }
                    )
                ) {
                    DebugView(store: store.scope(state: \.debug, action: StockPhoto.Action.debug))
                }
                #endif
                .onAppear {
                    // Check existing access token for auth;
                    // present login screen if not exists
                    viewStore.send(.login(.checkExistingAccessToken))
                }
            }
        }
    }
}
