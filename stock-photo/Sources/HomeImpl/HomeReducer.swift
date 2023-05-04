import ComposableArchitecture
import Home
import NetworkClient
import Segmentation
import StockPhotoFoundation
import SwiftUI

public struct Home<
    SegmentationReducer: ReducerProtocol<SegmentationState, SegmentationAction>
>: ReducerProtocol, Sendable {
    private var networkClient: NetworkClient
    private var segmentationReducerFactory: @Sendable () -> SegmentationReducer

    public init(
        networkClient: NetworkClient,
        segmentationReducerFactory: @escaping @Sendable () -> SegmentationReducer
    ) {
        self.networkClient = networkClient
        self.segmentationReducerFactory = segmentationReducerFactory
    }

    public var body: some ReducerProtocol<HomeState, HomeAction> {
        Reduce { state, action in
            switch action {
            case .selectedPhotosPickerItem(let photoPickerItem):
                guard let item = photoPickerItem else {
                    return .none
                }
                state.transferredImage = .loading
                return .task(
                    operation: {
                        let transferredImage = try await item.loadTransferable(type: Image.self)
                        guard let transferredImage = transferredImage else {
                            throw SPError.emptyTransferredImage
                        }
                        return .didCompleteTransferImage(.loaded(transferredImage))
                    },
                    catch: { error in
                        return .didCompleteTransferImage(.failed(SPError.catch(error)))
                    }
                )
            case .didCompleteTransferImage(let transferredImage):
                state.transferredImage = transferredImage
                return .none
            case .fetchImageProjects(let accessToken):
                return .task(
                    operation: {
                        let imageProjects = try await networkClient.listImageProjects(
                            ListImageProjectsRequest(
                                accessToken: accessToken
                            )
                        )
                        return .fetchedImageProjects(.loaded(imageProjects.imageProjects), accessToken: accessToken)
                    },
                    catch: { error in
                        return .fetchedImageProjects(.failed(SPError.catch(error)), accessToken: accessToken)
                    }
                )
            case .fetchedImageProjects(let imageProjects, let accessToken):
                if let error = imageProjects.error {
                    state.displayingErrors.append(error)
                }
                state.imageProjects = imageProjects
                guard let imageProjects = imageProjects.value else {
                    return .none
                }

                for imageProject in imageProjects {
                    if state.images[imageProject.imageFile] == nil || state.images[imageProject.imageFile] == .notLoaded {
                        return .send(.fetchImage(imageProject, accessToken: accessToken))
                    }
                }

                return .none
            case .fetchImage(let imageProject, let accessToken):
                // Load image project one by one if there's no in-progress loading.
                if state.images.contains(where: { $1.isLoading }) {
                    return .none
                }

                return .task(
                    operation: {
                        let imageLoadable = try await networkClient.fetchImage(
                            FetchImageRequest(
                                accessToken: accessToken,
                                fileName: imageProject.imageFile
                            )
                        )
                        return .fetchedImage(
                            .loaded(imageLoadable),
                            imageProject: imageProject,
                            accessToken: accessToken
                        )
                    },
                    catch: { error in
                        return .fetchedImage(
                            .failed(SPError.catch(error)),
                            imageProject: imageProject,
                            accessToken: accessToken
                        )
                    }
                )
            case .fetchedImage(let imageLoadable, let imageProject, let accessToken):
                if let error = imageLoadable.error {
                    state.displayingErrors.append(error)
                }

                state.images[imageProject.imageFile] = imageLoadable

                for imageProject in state.imageProjects.value ?? [] {
                    if state.images[imageProject.imageFile] == nil || state.images[imageProject.imageFile] == .notLoaded {
                        return .send(.fetchImage(imageProject, accessToken: accessToken))
                    }
                }

                return .none
            case .selectImageProjectID(let imageProjectID):
                state.selectedImageProjectID = imageProjectID
                return .none
            case .segmentation(let segmentationAction):
                switch segmentationAction {
                case .dismissSegmentation:
                    state.selectedImageProjectID = nil
                default:
                    break
                }
                return .none
            }
        }
        .ifLet(\.segmentation, action: /HomeAction.segmentation) {
            segmentationReducerFactory()
        }
    }
}

extension HomeState {
    var segmentation: SegmentationState? {
        get {
            guard let selectedImageProjectID = selectedImageProjectID, let image = images[selectedImageProjectID]?.value else {
                return nil
            }
            guard let accessToken = accessToken else {
                return nil
            }
            return SegmentationState(
                model: segmentationModel,
                accessToken: accessToken,
                fileName: selectedImageProjectID,
                image: image,
                displayErrors: displayingErrors
            )
        }

        set {
            guard let newValue = newValue else {
                return
            }

            self.segmentationModel = newValue.model
        }
    }
}
