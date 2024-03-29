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
import Nuke
import PhotosUI
import StockPhotoFoundation
import SwiftUI
import UIKit

public struct StockPhoto: ReducerProtocol, Sendable {
    public struct State: Equatable {
        public var destinations: [StockPhotoDestination]
        public var login: Login.State
        public var homeModel: HomeModel
        public var debugModel: DebugModel
        public var imageCapture: ImageCaptureState
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
            self.debugModel = DebugModel(
                endpoint: Endpoint(
                    rawValue: UserDefaults.standard.integer(
                        forKey: "debug.endpoint"
                    )
                ) ?? .development
            )
            self.imageCapture = ImageCaptureState()
            self.homeModel = HomeModel()
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

    private let networkClient: NetworkClient & NetworkEndpointAssignable
    private let dataCache: DataCaching

    public init(
        networkClient: NetworkClient & NetworkEndpointAssignable,
        dataCache: DataCaching
    ) {
        self.networkClient = networkClient
        self.dataCache = dataCache

        self.networkClient.endpoint = Endpoint(
            rawValue: UserDefaults.standard.integer(
                forKey: "debug.endpoint"
            )
        ) ?? .development
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
                    dataCache: dataCache,
                    segmentationReducerFactory: {
                        Segmentation(networkClient: networkClient)
                    }
                )
            }

            Scope(state: \.debug, action: /Action.debug) {
                Debug()
            }

            Reduce { state, action in
                func handleLoadableError<T>(
                    _ loadable: Loadable<T, SPError>
                ) -> EffectPublisher<StockPhoto.Action, Never> {
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

                func handleResultError<T>(_ result: Result<T, SPError>) -> EffectPublisher<StockPhoto.Action, Never> {
                    switch result {
                    case .failure(let error):
                        // If backend returns unauthorized, it is likely that the access token has expired. Clear and re-login.
                        if error.isUnauthorizedError {
                            state.login.isShowingLoginSheet = true
                            return .send(.login(.resetAccessToken))
                        } else {
                            state.displayingErrors.append(error)
                        }
                    case .success(_):
                        break
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
                    case .fetchedImage(let imageLoadable, project: let project, account: _):
                        if let maskDerivation = project.maskDerivation {
                            state.segmentationModel.segmentationResults[maskDerivation.mask.segID] = .loaded(SegmentationResult(id: maskDerivation.mask.maskID, mask: maskDerivation.mask.mask))
                            state.segmentationModel.pointSemantics[project.id] = maskDerivation.mask.pointSemantics
                            state.segmentationModel.segmentationResultConfirmations[maskDerivation.mask.segID] = .loaded(maskDerivation.mask.maskID)
                            if let maskedImage = imageLoadable.value?.maskedImage {
                                state.segmentationModel.segmentedImage[maskDerivation.mask.segID] = maskedImage
                            }
                        }
                        return handleLoadableError(imageLoadable)
                    case .fetchedProjects(let projects, account: _):
                        return handleLoadableError(projects)
                    case .segmentation(let segmentationAction):
                        switch segmentationAction {
                        case .didCompleteSegmentation(let masksLoadable, segmentedImage: _, segID: _):
                            return handleLoadableError(masksLoadable)
                        default:
                            return .none
                        }
                    case .logout:
                        return .send(.login(.resetAccessToken))
                    case .updateUploadProgress(let uploadFileUpdate, account: _):
                        return handleResultError(uploadFileUpdate)
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
                    case .renderAccessTokenInvalid:
                        return .send(.login(.renderAccessTokenInvalid))
                    case .setEndpoint(let endpoint):
                        networkClient.endpoint = endpoint
                        return .none
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
