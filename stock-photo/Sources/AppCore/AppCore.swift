import ComposableArchitecture
import Dispatch

public struct StockPhoto: ReducerProtocol {
    public enum State: Equatable {
        case main

        public init() { self = .main }
    }

    public enum Action: Equatable {
    }

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            }
        }
    }
}
