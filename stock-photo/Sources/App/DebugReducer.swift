import ComposableArchitecture
import Dependencies
import Login

public struct Debug: ReducerProtocol, Sendable {
    public var body: some ReducerProtocol<DebugState, DebugAction> {
        Reduce { state, action in
            switch action {
            case .setPresentDebugSheet(let isPresentingDebugSheet):
                state.isPresentingDebugSheet = isPresentingDebugSheet
                return .none
            case .wreckAccessToken:
                // Handled by parent
                return .none
            }
        }
    }
}
