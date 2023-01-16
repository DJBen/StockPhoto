import AppCore
import ComposableArchitecture
import ImageCaptureUI
import SwiftUI

public struct AppView: View {
    let store: StoreOf<StockPhoto>

    public init(store: StoreOf<StockPhoto>) {
        self.store = store
    }

    public var body: some View {
        SwitchStore(self.store) {
            CaseLet(state: /StockPhoto.State.imageCapture, action: StockPhoto.Action.imageCapture) { store in
                ImageCaptureView(store: store)
            }
        }
    }
}
