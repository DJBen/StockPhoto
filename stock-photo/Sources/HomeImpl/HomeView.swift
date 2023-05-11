import ComposableArchitecture
import Home
import Navigation
import PhotosUI
import Segmentation
import StockPhotoFoundation
import StockPhotoUI
import SwiftUI

public struct HomeView<
    SegmentationReducer: ReducerProtocol<SegmentationState, SegmentationAction>,
    SegmentationViewType: View
>: View {
    let store: StoreOf<Home<SegmentationReducer>>
    let segmentViewBuilder: (StoreOf<SegmentationReducer>) -> SegmentationViewType

    struct ViewState: Equatable {
        var account: Account?
        var selectedPhotosPickerItem: PhotosPickerItem?
        var transferredImage: Loadable<TransferredImage, SPError>
        var uploadState: UploadFileState?
        var projects: Loadable<[Project], SPError>
        var selectedProjectID: Int?

        struct ImageItem: Equatable {
            let imageID: Int
            let projectImagesLoadable: Loadable<ProjectImages, SPError>
        }

        var imageItems: [ImageItem]

        static func project(_ homeState: HomeState) -> ViewState {
            ViewState(
                account: homeState.account,
                selectedPhotosPickerItem: homeState.selectedPhotosPickerItem,
                transferredImage: homeState.transferredImage,
                uploadState: homeState.uploadState,
                projects: homeState.projects,
                selectedProjectID: homeState.selectedProjectID,
                imageItems: homeState.projects.value?.map { project in
                    ImageItem(
                        imageID: project.id,
                        projectImagesLoadable: homeState.images[project.id] ?? .loading
                    )
                } ?? []
            )
        }
    }

    public init(
        store: StoreOf<Home<SegmentationReducer>>,
        segmentViewBuilder: @escaping (StoreOf<SegmentationReducer>) -> SegmentationViewType
    ) {
        self.store = store
        self.segmentViewBuilder = segmentViewBuilder
    }

    public var body: some View {
        WithViewStore(
            store,
            observe: ViewState.project
        ) { viewStore in
            VStack {
                if viewStore.projects.isLoading {
                    Spacer()
                    ProgressView {
                        Text(
                            "Loading projects...",
                            comment: "The loading text of the listing image request."
                        )
                        .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else if viewStore.projects.error != nil {
                    Spacer()
                    Button {
                        guard let account = viewStore.account else {
                            return
                        }
                        viewStore.send(.retryFetchingProjects(account: account))
                    } label: {
                        Text(
                            "Retry",
                            comment: "The retry button text of the listing image request."
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                } else {
                    List(
                        selection: viewStore.binding(
                            get: \.selectedProjectID,
                            send: HomeAction.selectProjectID
                        )
                    ) {
                        ForEach(viewStore.imageItems, id: \.imageID) { item in
                            NavigationLink(
                                value: StockPhotoDestination.selectedProject(item.imageID)
                            ) {
                                Group {
                                    if let image = item.projectImagesLoadable.value?.image {
                                        Image(
                                            uiImage: image
                                        )
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(maxHeight: 100)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                HStack(spacing: 16) {
                    Button(action: {
                        // Implement your photo-taking functionality here
                        print("Take Photos button tapped")
                    }) {
                        Text(
                            "Take photos"
                        )
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    PhotosPicker(
                        selection: viewStore.binding(
                            get: \.selectedPhotosPickerItem,
                            send: HomeAction.selectedPhotosPickerItem
                        ),
                        matching: .images
                    ) {
                        Text(
                            "Choose from album"
                        )
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        action: {
                            viewStore.send(.logout)
                        }
                    ) {
                        Text(
                            "Log out",
                            comment: "The log out button on the home screen"
                        )
                        .tint(.red)
                    }
                }
            }
            .onAppear {
                guard let account = viewStore.account else {
                    return
                }
                viewStore.send(
                    .fetchProjects(account: account)
                )
            }
            .onChange(of: viewStore.account) { newAccount in
                guard let newAccount = newAccount else {
                    return
                }
                viewStore.send(
                    .fetchProjects(account: newAccount)
                )
            }
            .fullScreenCover(
                item: Binding<UploadFileState?>(
                    get: {
                        viewStore.uploadState
                    },
                    set: { _ in }
                )
            ) { uploadFileState in
                TranslucentFullScreenCover {
                    FileUploadView(
                        image: uploadFileState.image,
                        totalBytesSent: uploadFileState.totalByteSent ?? 0,
                        totalBytesExpectedToSend: uploadFileState.totalBytesExpectedToSend ?? 0,
                        onCancel: {
                            viewStore.send(.cancelUpload)
                        }
                    )
                }
            }
            .navigationDestination(for: StockPhotoDestination.self) { destination in
                switch destination {
                case .postImageCapture(_):
                    EmptyView()
                case .selectedProject(let imageID):
                    IfLetStore(
                        store.scope(
                            state: SegmentationState.projectToHomeState(
                                imageID: imageID,
                                projectImagesLoadable: viewStore.imageItems.first {
                                    $0.imageID == imageID
                                }?.projectImagesLoadable,
                                projects: viewStore.projects
                            ),
                            action: HomeAction.segmentation
                        ),
                        then: segmentViewBuilder
                    )
                }
            }
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    struct MockSegmentationReducer: ReducerProtocol, Sendable {
//        public var body: some ReducerProtocol<SegmentationState, SegmentationAction> {
//            EmptyReducer()
//        }
//    }
//
//    static var previews: some View {
//        HomeView<MockSegmentationReducer>(
//            store: Store(
//                initialState: HomeState(
//                    accessToken: nil,
//                    selectedPhotosPickerItem: nil,
//                    transferredImage: .notLoaded,
//                    projects: .notLoaded,
//                    images: [:],
//                    selectedProject: nil,
//                    segmentationResults: [:]
//                ),
//                reducer: MockSegmentationReducer()
//            )
//        )
//    }
//}
