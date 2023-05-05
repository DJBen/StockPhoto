import ComposableArchitecture
import Home
import Navigation
import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI

public struct HomeView<
    SegmentationReducer: ReducerProtocol<SegmentationState, SegmentationAction>,
    SegmentationViewType: View
>: View {
    let store: StoreOf<Home<SegmentationReducer>>
    let segmentViewBuilder: (StoreOf<SegmentationReducer>) -> SegmentationViewType

    struct ViewState: Equatable {
        var accessToken: String?
        var selectedPhotosPickerItem: PhotosPickerItem?
        var transferredImage: Loadable<Image, SPError>
        var imageProjects: Loadable<[ImageProject], SPError>
        var selectedImageProjectID: Int?

        struct ImageItem: Equatable {
            let imageID: Int
            let imageLoadable: Loadable<UIImage, SPError>
        }

        var imageItems: [ImageItem]

        static func project(_ homeState: HomeState) -> ViewState {
            ViewState(
                accessToken: homeState.accessToken,
                selectedPhotosPickerItem: homeState.selectedPhotosPickerItem,
                transferredImage: homeState.transferredImage,
                imageProjects: homeState.imageProjects,
                selectedImageProjectID: homeState.selectedImageProjectID,
                imageItems: homeState.imageProjects.value?.map { imageProject in
                    ImageItem(
                        imageID: imageProject.id,
                        imageLoadable: homeState.images[imageProject.id] ?? .loading
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
                if viewStore.imageProjects.isLoading {
                    Spacer()
                    ProgressView {
                        Text(
                            "Loading projects...",
                            comment: "The loading text of the listing image request."
                        )
                        .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List(
                        selection: viewStore.binding(
                            get: \.selectedImageProjectID,
                            send: HomeAction.selectImageProjectID
                        )
                    ) {
                        ForEach(viewStore.imageItems, id: \.imageID) { item in
                            NavigationLink(
                                value: StockPhotoDestination.selectedImageProject(item.imageID)
                            ) {
                                Group {
                                    if let image = item.imageLoadable.value {
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
                guard let accessToken = viewStore.accessToken else {
                    return
                }
                viewStore.send(
                    .fetchImageProjects(accessToken: accessToken)
                )
            }
            .onChange(of: viewStore.accessToken) { newAccessToken in
                guard let newAccessToken = newAccessToken else {
                    return
                }
                viewStore.send(
                    .fetchImageProjects(accessToken: newAccessToken)
                )
            }
            .navigationDestination(for: StockPhotoDestination.self) { destination in
                switch destination {
                case .postImageCapture(_):
                    EmptyView()
                case .selectedImageProject(let imageID):
                    IfLetStore(
                        store.scope(
                            state: SegmentationState.projectToHomeState(
                                imageID: imageID,
                                imageLoadable: viewStore.imageItems.first { $0.imageID == imageID }?.imageLoadable,
                                imageProjects: viewStore.imageProjects
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
//                    imageProjects: .notLoaded,
//                    images: [:],
//                    selectedImageProject: nil,
//                    segmentationResult: [:]
//                ),
//                reducer: MockSegmentationReducer()
//            )
//        )
//    }
//}
