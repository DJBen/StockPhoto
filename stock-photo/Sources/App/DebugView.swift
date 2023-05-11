import ComposableArchitecture
import SwiftUI

struct DebugView: View {
    let store: StoreOf<Debug>

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationStack {
                Form {
                    Section(header: Text(verbatim: "Auth testing")) {
                        Button("Wreck access token") {
                            viewStore.send(.renderAccessTokenInvalid)
                        }
                    }
                }
            }
        }
    }
}
