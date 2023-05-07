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
            case .selectProjectID(let projectID):
                state.selectedProjectID = projectID
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
            guard let selectedProjectID = selectedProjectID, let projectImages = images[selectedProjectID]?.value, let project = projects.value?.first(where: { $0.id ==  selectedProjectID }) else {
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
