import ComposableArchitecture
import ImageViewer
import PhotosUI
import Segmentation
import StockPhotoFoundation
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
                        image: viewStore.image,
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
                                    imageID: viewStore.imageProject.id
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
                                pointSemantics: viewStore.currentPointSemantics
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
                    TranslucentFullScreenCover(
                    )
                }
                .onDisappear {
                    viewStore.send(.dismissSegmentation)
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
        if let segmentedImage = viewStore.segmentedImage[viewStore.segID] {
            ToolbarItemGroup(
                placement: .bottomBar
            ) {
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

                Spacer()
            }
        } else {
            ToolbarItemGroup(
                placement: .bottomBar
            ) {
                Button(action: {
                    viewStore.send(.undoPointSemantic(imageID: viewStore.imageProject.id))
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
                            accessToken: viewStore.accessToken,
                            sourceImage: viewStore.image
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

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for pointSemantic in pointSemantics {
            let x = CGFloat(pointSemantic.point.x)
            let y = CGFloat(pointSemantic.point.y)
            let circleRadius: CGFloat = 12.0
            let circleRect = CGRect(x: x - circleRadius, y: y - circleRadius, width: circleRadius * 2, height: circleRadius * 2)
            path.addEllipse(in: circleRect)
        }

        return path
    }
}

struct TranslucentFullScreenCover: View {
    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundBlurView())
        .edgesIgnoringSafeArea(.all)
    }
}

struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct SegmentationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SegmentationView(
                store: StoreOf<Segmentation>(
                    initialState: SegmentationState(
                        model: SegmentationModel(),
                        accessToken: "",
                        imageProject: ImageProject(id: 0, fileName: "Example.jpg"),
                        image: UIImage(named: "Example", in: .module, with: nil)!
                    ),
                    reducer: EmptyReducer()
                )
            )
        }
    }
}
