import ComposableArchitecture
import Dependencies
import Foundation
import Login

public struct Debug: ReducerProtocol, Sendable {
    public var body: some ReducerProtocol<DebugState, DebugAction> {
        Reduce { state, action in
            switch action {
            case .setPresentDebugSheet(let isPresentingDebugSheet):
                state.isPresentingDebugSheet = isPresentingDebugSheet
                return .none
            case .renderAccessTokenInvalid:
                return .send(.setPresentDebugSheet(false))
            case .setEndpoint(let endpoint):
                state.endpoint = endpoint
                UserDefaults.standard.setValue(
                    endpoint.rawValue,
                    forKey: "debug.endpoint"
                )
                return .none
            }
        }
    }
}
