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
            case .fetchProjects(let accessToken):
                guard state.projects.isLoading else {
                    return .none
                }
                return .task(
                    operation: {
                        let projects = try await networkClient.listProjects(
                            ListProjectsRequest(
                                accessToken: accessToken
                            )
                        )
                        return .fetchedProjects(.loaded(projects.projects), accessToken: accessToken)
                    },
                    catch: { error in
                        return .fetchedProjects(.failed(SPError.catch(error)), accessToken: accessToken)
                    }
                )
            case .fetchedProjects(let projects, let accessToken):
                state.projects = projects
                guard let projects = projects.value else {
                    return .none
                }

                for project in projects {
                    if state.images[project.id] == nil || state.images[project.id] == .notLoaded {
                        return .send(.fetchImage(project, accessToken: accessToken))
                    }
                }

                return .none
            case .fetchImage(let project, let accessToken):
                // Load image project one by one if there's no in-progress loading.
                if state.images.contains(where: { $1.isLoading }) {
                    return .none
                }

                return .task(
                    operation: {
                        let imageLoadable = try await networkClient.fetchImage(
                            FetchImageRequest(
                                accessToken: accessToken,
                                imageID: project.id
                            )
                        )
                        return .fetchedImage(
                            .loaded(imageLoadable),
                            project: project,
                            accessToken: accessToken
                        )
                    },
                    catch: { error in
                        return .fetchedImage(
                            .failed(SPError.catch(error)),
                            project: project,
                            accessToken: accessToken
                        )
                    }
                )
            case .fetchedImage(let imageLoadable, let project, let accessToken):
                state.images[project.id] = imageLoadable

                for project in state.projects.value ?? [] {
                    if state.images[project.id] == nil || state.images[project.id] == .notLoaded {
                        return .send(.fetchImage(project, accessToken: accessToken))
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
            guard let selectedProjectID = selectedProjectID, let image = images[selectedProjectID]?.value, let project = projects.value?.first(where: { $0.id ==  selectedProjectID }) else {
                return nil
            }
            guard let accessToken = accessToken else {
                return nil
            }
            return SegmentationState(
                model: segmentationModel,
                accessToken: accessToken,
                project: project,
                image: image
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
