import ComposableArchitecture
import ImageViewer
import PhotosUI
import PreviewAssets
import Segmentation
import StockPhotoFoundation
import StockPhotoUI
import SwiftUI

public struct SegmentationView: View {
    let store: StoreOf<Segmentation>

    public init(store: StoreOf<Segmentation>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            ImageViewerReader { proxy in
                VStack(spacing: 0) {
                    ImageViewerView(
                        image: viewStore.projectImages.image,
                        onTap: { x, y in
                            // Don't add points if there is currently segmented image
                            if viewStore.segmentedImage[viewStore.segID] != nil {
                                return
                            }
                            // Don't add points that are within 10px of each other
                            let point = Point(x: x, y: y)
                            if viewStore.currentPointSemantics.contains(where: {
                                $0.point.distance(to: point) < 10
                            }) {
                                return
                            }
                            viewStore.send(
                                .addPointSemantic(
                                    PointSemantic(
                                        point: point,
                                        label: .foreground
                                    ),
                                    imageID: viewStore.project.id
                                )
                            )
                        }
                    ) {
                        if let segmentedImage = viewStore.segmentedImage[viewStore.segID] {
                            Image(
                                uiImage: segmentedImage
                            )
                            .background {
                                Color.black.opacity(0.75)
                            }
                        } else {
                            ForegroundOverlay(
                                pointSemantics: viewStore.currentPointSemantics,
                                radius: min(
                                    viewStore.projectImages.image.size.width,
                                    viewStore.projectImages.image.size.height
                                ) / 100
                            )
                            .foregroundColor(.green)
                        }
                    }

                    markingInstructionsLabel(viewStore)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent(viewStore)
                }
                .fullScreenCover(
                    isPresented: Binding<Bool>(
                        get: {
                            viewStore.isSegmenting
                        },
                        set: { _ in }
                    )
                ) {
                    TranslucentFullScreenCover {
                        ProgressView {
                            VStack(spacing: 8) {
                                Text(
                                    "Figuring out the contour...",
                                    comment: "The loading text of the segmentation request."
                                )
                                .multilineTextAlignment(.center)

                                Text(
                                    "It may take extra long if our server boots from cold start",
                                    comment: "The secondary loading text of the segmentation request."
                                )
                                .foregroundColor(.secondary)
                                .font(.caption)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .alert(
                    isPresented: viewStore.binding(
                        get: \.isShowingDeletingSegmentationAlert,
                        send: SegmentationAction.setIsShowingDeletingSegmentationAlert
                    )
                ) {
                    Alert(
                        title: Text(
                            "Discard image",
                            comment: "The title of alert view when confirming discarding segmented image."
                        ),
                        message: Text(
                            "Are you sure you want to discard this extraction of your subject?",
                            comment: "The message of alert view when confirming discarding segmented image."
                        ),
                        primaryButton: .destructive(
                            Text(
                                "Discard",
                                comment: "The primary button of alert view when confirming discarding segmented image."
                            )
                        ) {
                            viewStore.send(.discardSegmentedImage(viewStore.segID))
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    @ToolbarContentBuilder private func toolbarContent(
        _ viewStore: ViewStoreOf<Segmentation>
    ) -> some ToolbarContent {
        if let segmentationResult = viewStore.segmentationResults[viewStore.segID]?.value {
            ToolbarItemGroup(
                placement: .bottomBar
            ) {
                if !(viewStore.isConfirmingSegmentation || viewStore.hasConfirmedSegmentation) {
                    Button(
                        role: .destructive,
                        action: {
                            viewStore.send(.setIsShowingDeletingSegmentationAlert(true))
                        }
                    ) {
                        Image(
                            systemName: "trash"
                        )
                        .tint(.red)
                    }
                    .disabled(viewStore.currentPointSemantics.isEmpty)

                }

                Spacer()

                Button(action: {
                    viewStore.send(
                        .confirmSegmentationResult(
                            maskID: segmentationResult.id,
                            segID: viewStore.segID,
                            account: viewStore.account ?? Account(accessToken: "invalid", userID: "")
                        )
                    )
                }) {
                    HStack(spacing: 8) {
                        if viewStore.isConfirmingSegmentation {
                            ProgressView()
                        }

                        Text(
                            "Proceed"
                        )
                        .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewStore.isConfirmingSegmentation)
            }
        } else {
            ToolbarItemGroup(
                placement: .bottomBar
            ) {
                Button(action: {
                    viewStore.send(.undoPointSemantic(imageID: viewStore.project.id))
                }) {
                    Image(
                        systemName: "arrow.uturn.backward"
                    )
                }
                .disabled(viewStore.currentPointSemantics.isEmpty)

                Spacer()

                Button(action: {
                    viewStore.send(
                        .requestSegmentation(
                            viewStore.segID,
                            account: viewStore.account ?? Account(accessToken: "invalid", userID: ""),
                            sourceImage: viewStore.projectImages.image
                        )
                    )
                }) {
                    Text(
                        "Extract subject"
                    )
                    .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewStore.currentPointSemantics.isEmpty || viewStore.isSegmenting)
            }
        }
    }

    @ViewBuilder private func markingInstructionsLabel(_ viewStore: ViewStoreOf<Segmentation>) -> some View {
        Group {
            if viewStore.segmentedImage[viewStore.segID] != nil {

            } else {
                HStack(alignment: .lastTextBaseline) {
                    Image(systemName: "circle.fill").foregroundColor(.green)
                    Text(
                        "Identify the subject you want to extract from the background. In most cases, one is sufficient. You may mark multiple regions if it doesn't pick up a complex subject."
                    )
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
                }
            }
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct ForegroundOverlay: Shape {
    var pointSemantics: [PointSemantic]
    var radius: CGFloat = 12.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for pointSemantic in pointSemantics {
            let x = CGFloat(pointSemantic.point.x)
            let y = CGFloat(pointSemantic.point.y)
            let circleRect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            path.addEllipse(in: circleRect)
        }

        return path
    }
}

struct SegmentationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SegmentationView(
                store: StoreOf<Segmentation>(
                    initialState: SegmentationState(
                        model: SegmentationModel(),
                        account: Account(accessToken: "", userID: ""),
                        project: Project(image: ImageDescriptor(id: 0), maskDerivation: nil),
                        projectImages: ProjectImages(
                            image: UIImage(named: "Example", in: .previewAssets, with: nil)!,
                            maskedImage: nil
                        )
                    ),
                    reducer: EmptyReducer()
                )
            )
        }
    }
}
