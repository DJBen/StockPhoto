import ComposableArchitecture
import Dispatch
import Login
import ImageCapture
import SwiftUI

public struct StockPhoto: ReducerProtocol {
    /// The navigation destination identifier
    public enum Destination: Equatable {
        case todo
    }

    public struct State: Equatable {
        public var destinations: [Destination]
        public var login: Login.State
        public var imageCapture: ImageCapture.State

        public init() {
            self.destinations = []
            self.login = Login.State()
            self.imageCapture = ImageCapture.State()
        }
    }

    public enum Action: Equatable {
        // Stack-based navigation
        case navigationChanged([Destination])

        case login(Login.Action)
        case imageCapture(ImageCapture.Action)
    }

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        CombineReducers {
            Scope(state: \.login, action: /Action.login) {
                Login()
            }

            Scope(state: \.imageCapture, action: /Action.imageCapture) {
                ImageCapture()
            }

            Reduce { state, action in
                switch action {
                case .navigationChanged(let destinations):
                    state.destinations = destinations
                    return .none
                case .login(let loginAction):
                    switch loginAction {
                    case .didAuthenticate(accessToken: let accessToken, userID: _):
                        state.imageCapture.accessToken = accessToken
                    default:
                        break
                    }
                    return .none
                case .imageCapture(_):
                    return .none
                }
            }
        }
    }
}
