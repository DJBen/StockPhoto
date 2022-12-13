import AppCore
import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    let store: StoreOf<StockPhoto>

    public init(store: StoreOf<StockPhoto>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { store in

        }
    }
}
