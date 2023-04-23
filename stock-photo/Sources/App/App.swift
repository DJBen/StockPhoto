import ComposableArchitecture
import Dispatch
import Login
import ImageCapture
import SwiftUI

public struct StockPhoto: ReducerProtocol {
    public struct State: Equatable {
        /// The navigation destination identifier
        public enum Destination: Equatable {
            case login
            case imageCapture
        }

        public var destinations: [Destination]
        public var login: Login.State
        public var imageCapture: ImageCapture.State?

        public init() {
            self.destinations = []
            self.login = Login.State()
            self.imageCapture = nil
        }
    }

    public enum Action: Equatable {
        // Navigation
        case navigationChanged([State.Destination])
        case navigateToImageCapture

        case login(Login.Action)
        case imageCapture(ImageCapture.Action)
    }

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        CombineReducers {
            Scope(state: \.login, action: /Action.login) {
                Login()
            }

            Reduce { state, action in
                switch action {
                case .navigationChanged(let destinations):
                    state.destinations = destinations
                    return .none
                case .navigateToImageCapture:
                    state.destinations.append(.imageCapture)
                    return .none
                case .login(_):
                    return .none
                case .imageCapture(_):
                    return .none
                }
            }
        }
        .ifLet(\.imageCapture, action: /Action.imageCapture) {
            ImageCapture()
        }
    }
}
