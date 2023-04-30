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
    private var segmentationFactory: @Sendable () -> SegmentationReducer

    public init(
        networkClient: NetworkClient,
        segmentationFactory: @escaping @Sendable () -> SegmentationReducer
    ) {
        self.networkClient = networkClient
        self.segmentationFactory = segmentationFactory
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
                        if let spError = error as? SPError {
                            return .didCompleteTransferImage(.failed(spError))
                        }
                        return .didCompleteTransferImage(.failed(SPError.unknownError))
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
                        if let spError = error as? SPError {
                            return .didCompleteTransferImage(.failed(spError))
                        }
                        return .fetchedImageProjects(.failed(SPError.unknownError), accessToken: accessToken)
                    }
                )
            case .fetchedImageProjects(let imageProjects, let accessToken):
                state.imageProjects = imageProjects
                guard let imageProjects = imageProjects.value else {
                    return .none
                }

                for imageProject in imageProjects {
                    if state.images[imageProject.id] == nil || state.images[imageProject.id] == .notLoaded {
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
                        if let spError = error as? SPError {
                            return .fetchedImage(
                                .failed(spError),
                                imageProject: imageProject,
                                accessToken: accessToken
                            )
                        }
                        return .fetchedImage(.failed(SPError.unknownError), imageProject: imageProject, accessToken: accessToken)
                    }
                )
            case .fetchedImage(let imageLoadable, let imageProject, let accessToken):
                state.images[imageProject.id] = imageLoadable

                for imageProject in state.imageProjects.value ?? [] {
                    if state.images[imageProject.id] == nil || state.images[imageProject.id] == .notLoaded {
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
            segmentationFactory()
        }
    }
}

extension HomeState {
    var segmentation: SegmentationState? {
        get {
            guard let selectedImageProjectID = selectedImageProjectID, let image = images[selectedImageProjectID]?.value else {
                return nil
            }
            return SegmentationState(
                fileID: selectedImageProjectID,
                image: image,
                segmentationResult: segmentationResult
            )
        }

        set {
            guard let newValue = newValue else {
                return
            }
            self.segmentationResult = newValue.segmentationResult
        }
    }
}
