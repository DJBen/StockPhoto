import ComposableArchitecture
import Home
import NetworkClient
import Nuke
import Segmentation
import StockPhotoFoundation
import SwiftUI
import UIImageExtensions

public struct Home<
    SegmentationReducer: ReducerProtocol<SegmentationState, SegmentationAction>
>: ReducerProtocol, Sendable {
    private let networkClient: NetworkClient
    private let dataCache: DataCaching
    private let imageEncoder: ImageEncoders.Default = .init()
    private let imageDecoder: ImageDecoders.Default = .init()
    private let segmentationReducerFactory: @Sendable () -> SegmentationReducer

    public init(
        networkClient: NetworkClient,
        dataCache: DataCaching,
        segmentationReducerFactory: @escaping @Sendable () -> SegmentationReducer
    ) {
        self.networkClient = networkClient
        self.dataCache = dataCache
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
                        let imageData = try await item.loadTransferable(type: Data.self)
                        let image = UIImage(data: imageData!)

                        guard let resizedImageData = image?.resizedImageBelowSizeLimit(2 * 1024 * 1024)?.jpegData(compressionQuality: 1.0), let contentType = item.supportedContentTypes.first else {
                            throw SPError.emptyTransferredImage
                        }
                        return .didCompleteTransferImage(
                            .loaded(TransferredImage(imageData: resizedImageData, mimeType: contentType))
                        )
                    },
                    catch: { error in
                        return .didCompleteTransferImage(
                            .failed(SPError.catch(error))
                        )
                    }
                )

            case .didCompleteTransferImage(let transferredImage):
                state.transferredImage = transferredImage

                if let image = transferredImage.value, let account = state.account {
                    return .send(.uploadImage(image, account: account))
                }
                return .none

            case .uploadImage(let image, let account):
                let id = UUID().uuidString
                state.uploadState = UploadFileState(
                    id: id,
                    image: UIImage(data: image.imageData)!
                )
                return .run(
                    operation: { send in
                        let stream = networkClient.uploadImage(
                            UploadImageRequest(
                                id: id,
                                account: account,
                                image: image.imageData,
                                mimeType: image.mimeType.preferredMIMEType ?? "image/jpeg"
                            )
                        )
                        for try await update in stream {
                            await send(
                                .updateUploadProgress(
                                    .success(update),
                                    account: account
                                )
                            )
                        }
                    },
                    catch: { error, send in
                        await send(
                            .updateUploadProgress(
                                .failure(SPError.catch(error)),
                                account: account
                            )
                        )
                    }
                )
                .cancellable(id: id)

            case .updateUploadProgress(let fileUpdate, let account):
                state.transferredImage = .notLoaded

                switch fileUpdate {
                case .success(let update):
                    withAnimation {
                        state.uploadState?.update = update
                    }

                    switch update {
                    case .completed(imageID: _):
                        state.uploadState = nil

                        return .send(.refreshProjects(account: account))
                    case .inProgress(totalBytesSent: _, totalBytesExpectedToSend: _):
                        break
                    }
                case .failure(_):
                    state.transferredImage = .notLoaded
                    state.uploadState = nil
                }

                return .none

            case .cancelUpload:
                guard let uploadState = state.uploadState else {
                    return .none
                }

                state.uploadState = nil
                state.transferredImage = .notLoaded

                return .cancel(id: uploadState.id)

            case .deleteImage(imageID: let imageID, account: let account):
                return .task(
                    operation: {
                        let response = try await networkClient.deleteImage(
                            DeleteImageRequest(account: account, imageID: imageID)
                        )
                        return .didCompleteDeleteImage(
                            .loaded(response.imageID),
                            account: account
                        )
                    },
                    catch: { error in
                        .didCompleteDeleteImage(
                            .failed(SPError.catch(error)),
                            account: account
                        )
                    }
                )

            case .didCompleteDeleteImage(let deletingImageID, let account):
                state.deletingImageID = deletingImageID

                if let deletedImageID = state.deletingImageID.value {
                    // Delete the projects locally
                    state.projects = state.projects.map { projects in
                        projects.filter { $0.id != deletedImageID }
                    }

                    return .send(.refreshProjects(account: account))
                }

                return .none

            case .fetchProjects(let account):
                guard state.projects.isLoading else {
                    return .none
                }
                return .task(
                    operation: {
                        let projects = try await networkClient.listProjects(
                            ListProjectsRequest(
                                account: account
                            )
                        )
                        return .fetchedProjects(.loaded(projects.projects), account: account)
                    },
                    catch: { error in
                        return .fetchedProjects(.failed(SPError.catch(error)), account: account)
                    }
                )

            case .retryFetchingProjects(let account):
                guard state.projects.error != nil else {
                    return .none
                }
                state.projects = .loading
                return .send(.fetchProjects(account: account))

            case .refreshProjects(let account):
                state.projects.reload()

                return .send(.fetchProjects(account: account))

            case .fetchedProjects(let projects, let account):
                state.projects = projects
                guard let projects = projects.value else {
                    return .none
                }

                for project in projects {
                    if state.images[project.id] == nil || state.images[project.id] == .notLoaded {
                        return .send(.fetchImage(project, account: account))
                    }
                }

                return .none

            case .selectProjectID(let projectID):
                state.selectedProjectID = projectID
                return .none

            case .fetchImage(let project, let account):
                // Load image project one by one if there's no in-progress loading.
                if state.images.contains(where: { $1.isLoading }) {
                    return .none
                }

                return .task(
                    operation: {
                        let image = try await networkClient.fetchImage(
                            FetchImageRequest(
                                account: account,
                                imageID: project.id,
                                maskDerivation: project.maskDerivation
                            )
                        )
                        let projectImages = ProjectImages(
                            image: image,
                            maskedImage: try project.maskDerivation.flatMap {
                                let cacheKey = "\(account.userID)_\(project.image)_\($0.id)"
                                if dataCache.containsData(for: cacheKey), let imageData = dataCache.cachedData(for: cacheKey) {
                                    return try imageDecoder.decode(imageData).image
                                }

                                if let croppedImage = image.croppedImage(using: $0.mask.mask.counts) {
                                    if let encodedImageData = imageEncoder.encode(croppedImage) {
                                        dataCache.storeData(encodedImageData, for: cacheKey)
                                    }
                                    return croppedImage
                                }
                                return nil
                            }
                        )

                        return .fetchedImage(
                            .loaded(projectImages),
                            project: project,
                            account: account
                        )
                    },
                    catch: { error in
                        return .fetchedImage(
                            .failed(SPError.catch(error)),
                            project: project,
                            account: account
                        )
                    }
                )
            case .fetchedImage(let projectImagesLoadable, let project, let account):
                state.images[project.id] = projectImagesLoadable

                // Fetch projects one by one
                for project in state.projects.value ?? [] {
                    if state.images[project.id] == nil || state.images[project.id] == .notLoaded {
                        return .send(.fetchImage(project, account: account))
                    }
                }

                return .none
            case .segmentation(_):
                return .none
            case .logout:
                // Handled by the parent
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
            guard let selectedProjectID = selectedProjectID, let projectImages = model.images[selectedProjectID]?.value, let project = model.projects.value?.first(where: { $0.id ==  selectedProjectID }) else {
                return nil
            }
            guard let account = account else {
                return nil
            }
            return SegmentationState(
                model: segmentationModel,
                account: account,
                project: project,
                projectImages: projectImages
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
