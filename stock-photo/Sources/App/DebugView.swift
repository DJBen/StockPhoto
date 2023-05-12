import ComposableArchitecture
import StockPhotoFoundation
import SwiftUI

struct DebugView: View {
    let store: StoreOf<Debug>

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationStack {
                Form {
                    Section(
                        header: Text("Environment")
                    ) {
                        Picker(
                            selection: viewStore.binding(
                                get: \.endpoint,
                                send: DebugAction.setEndpoint
                            ),
                            content: {
                                Text("Development").tag(Endpoint.development)
                                Text("Production").tag(Endpoint.production)
                            },
                            label: {
                                Text("Endpoint")
                            }
                        )
                    }

                    Section(
                        header: Text(
                            "Auth testing"
                        ),
                        footer: Text(
                            "Makes access token invalid, so it fails the authentication on the next call.",
                            comment: "The caption of invalidate access token option in the debug menu"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ) {
                        Button("Invalidate access token") {
                            viewStore.send(.renderAccessTokenInvalid)
                        }
                    }
                }
                .navigationTitle("Debug")
            }
        }
    }
}
