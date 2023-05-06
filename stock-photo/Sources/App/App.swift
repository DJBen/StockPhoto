import ComposableArchitecture
import Dispatch
import Login
import Home
import HomeImpl
import ImageCapture
import ImageCaptureImpl
import Segmentation
import SegmentationImpl
import Navigation
import NetworkClient
import PhotosUI
import StockPhotoFoundation
import SwiftUI
import UIKit

public struct StockPhoto: ReducerProtocol, Sendable {
    public struct State: Equatable {
        public var destinations: [StockPhotoDestination]
        public var login: Login.State
        public var debugModel: DebugModel
        public var imageCapture: ImageCaptureState
        public var selectedPhotoPickerItem: PhotosPickerItem?
        public var transferredImage: Loadable<Image, SPError>
        public var imageProjects: Loadable<[ImageProject], SPError>
        public var images: [Int: Loadable<UIImage, SPError>]
        public var segmentationModel: SegmentationModel
        public var displayingErrors: [SPError]
        
        public var home: HomeState {
            get {
                HomeState.project(self)
            }
            set {
                newValue.apply(&self)
            }
        }

        public var debug: DebugState {
            get {
                DebugState.project(self)
            }
            set {
                newValue.apply(&self)
            }
        }

        public init() {
            self.destinations = []
            self.login = Login.State()
            self.debugModel = DebugModel()
            self.imageCapture = ImageCaptureState()
            self.selectedPhotoPickerItem = nil
            self.transferredImage = .notLoaded
            self.imageProjects = .loading
            self.images = [:]
            self.segmentationModel = SegmentationModel()
            self.displayingErrors = []
        }

        var alertState: AlertState<Action>? {
            guard let firstError = displayingErrors.first else {
                return nil
            }
            return AlertState(
                title: {
                    TextState(firstError.title)
                },
                message: {
                    TextState(firstError.localizedDescription)
                }
            )
        }
    }

    public enum Action: Equatable {
        // Stack-based navigation
        case navigationChanged([StockPhotoDestination])

        case home(HomeAction)
        case login(Login.Action)
        case imageCapture(ImageCaptureAction)
        case debug(DebugAction)
        case dismissError
    }

    private var networkClient: NetworkClient

    public init(
        networkClient: NetworkClient
    ) {
        self.networkClient = networkClient
    }

    public var body: some ReducerProtocol<State, Action> {
        CombineReducers {
            Scope(state: \.login, action: /Action.login) {
                Login(networkClient: networkClient)
            }

            Scope(state: \.imageCapture, action: /Action.imageCapture) {
                ImageCapture()
            }

            Scope(state: \.home, action: /Action.home) {
                Home(
                    networkClient: networkClient,
                    segmentationReducerFactory: {
                        Segmentation(networkClient: networkClient)
                    }
                )
            }

            Scope(state: \.debug, action: /Action.debug) {
                Debug()
            }

            Reduce { state, action in
                func handleLoadableError<T>(_ loadable: Loadable<T, SPError>) -> EffectPublisher<StockPhoto.Action, Never> {
                    if let error = loadable.error {
                        // If backend returns unauthorized, it is likely that the access token has expired. Clear and re-login.
                        if error.isUnauthorizedError {
                            state.login.isShowingLoginSheet = true
                            return .send(.login(.resetAccessToken))
                        } else {
                            state.displayingErrors.append(error)
                        }
                    }
                    return .none
                }

                switch action {
                case .navigationChanged(let destinations):
                    state.destinations = destinations
                    return .none
                case .home(let homeAction):
                    switch homeAction {
                    case .didCompleteTransferImage(let transferredImage):
                        return handleLoadableError(transferredImage)
                    case .fetchedImage(let imageLoadable, imageProject: _, accessToken: _):
                        return handleLoadableError(imageLoadable)
                    case .fetchedImageProjects(let imageProjects, accessToken: _):
                        return handleLoadableError(imageProjects)
                    case .segmentation(let segmentationAction):
                        switch segmentationAction {
                        case .didCompleteSegmentation(let masksLoadable, segmentedImage: _, segID: _):
                            return handleLoadableError(masksLoadable)
                        default:
                            return .none
                        }
                    case .logout:
                        return .send(.login(.resetAccessToken))
                    default:
                        return .none
                    }
                case .login(let loginAction):
                    return .none
                case .imageCapture(let imageCaptureAction):
                    switch imageCaptureAction {
                    case .didCaptureImage(let capturedImage):
                        state.destinations.append(.postImageCapture(capturedImage))
                    case .dismissPostImageCapture:
                        state.destinations.removeLast()
                    default:
                        break
                    }
                    return .none
                case .debug(let debugAction):
                    switch debugAction {
                    case .setPresentDebugSheet(let isPresenting):
                        state.debug.isPresentingDebugSheet = isPresenting
                    case .wreckAccessToken:
                        return .send(.login(.wreckAccessToken))
                    }
                    return .none
                case .dismissError:
                    if state.displayingErrors.isEmpty {
                        return .none
                    }
                    state.displayingErrors.removeFirst()
                    return .none
                }
            }
        }
    }
}
