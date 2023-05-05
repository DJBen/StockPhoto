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
        public var imageCapture: ImageCaptureState
        public var selectedPhotoPickerItem: PhotosPickerItem?
        public var transferredImage: Loadable<Image, SPError>
        public var imageProjects: Loadable<[ImageProject], SPError>
        public var images: [String: Loadable<UIImage, SPError>]
        public var selectedImageProjectID: String?
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

        public init() {
            self.destinations = []
            self.login = Login.State()
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

            Reduce { state, action in
                func handleLoadableError<T>(_ loadable: Loadable<T, SPError>) {
                    if let error = loadable.error {
                        state.displayingErrors.append(error)

                        // If backend returns unauthorized, it is likely that the access token has expired. Clear and re-login.
                        if error.isUnauthorizedError {
                            state.login.accessToken = nil
                            state.login.isShowingLoginSheet = true
                        }
                    }
                }

                switch action {
                case .navigationChanged(let destinations):
                    state.destinations = destinations
                    return .none
                case .home(let homeAction):
                    switch homeAction {
                    case .didCompleteTransferImage(let transferredImage):
                        handleLoadableError(transferredImage)
                    case .fetchedImage(let imageLoadable, imageProject: _, accessToken: _):
                        handleLoadableError(imageLoadable)
                    case .fetchedImageProjects(let imageProjects, accessToken: _):
                        handleLoadableError(imageProjects)
                    case .segmentation(let segmentationAction):
                        switch segmentationAction {
                        case .didCompleteSegmentation(let masksLoadable, segmentedImage: _, segID: _):
                            handleLoadableError(masksLoadable)
                        default:
                            return .none
                        }
                    case .logout:
                        return .send(.login(.resetAccessToken))
                    default:
                        return .none
                    }
                    return .none
                case .login(let loginAction):
                    switch loginAction {
                    case .didAuthenticate(accessToken: let accessToken, userID: _):
                        state.imageCapture.accessToken = accessToken
                    default:
                        break
                    }
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
