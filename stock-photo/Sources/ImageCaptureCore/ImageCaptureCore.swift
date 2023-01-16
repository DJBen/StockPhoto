import ComposableArchitecture
import Dispatch
import ImageSegmentationClient

public struct ImageCapture: ReducerProtocol {
    public struct State: Equatable {

        public init() {}
    }

    public enum Action: Equatable {

    }

    @Dependency(\.imageSegmentationClient) var imageSegmentationClient

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {

            }
        }
    }
}
