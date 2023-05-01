import ComposableArchitecture
import ImageViewer
import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI

public struct SegmentationView: View {
    let store: StoreOf<Segmentation>

    @State var pointSemantics: [PointSemantic] = []

    public init(store: StoreOf<Segmentation>) {
        self.store = store
    }

    private func isSegmenting(_ viewStore: ViewStore<SegmentationState, SegmentationAction>) -> Bool {
        let segID = SegmentationIdentifier(
            fileName: viewStore.fileName,
            pointSemantics: pointSemantics
        )
        switch viewStore.segmentationResult[segID] {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            ImageViewerReader { proxy in
                VStack(spacing: 0) {
                    ImageViewerView(
                        image: viewStore.image,
                        onTap: { x, y in
                            // Don't add points that are within 10px of each other
                            let point = Point(x: x, y: y)
                            if pointSemantics.contains(where: {
                                $0.point.distance(to: point) < 10
                            }) {
                                return
                            }

                            pointSemantics.append(PointSemantic(point: point, label: .foreground))
                        }
                    ) {
                        ForegroundOverlay(
                            pointSemantics: pointSemantics
                        )
                        .foregroundColor(.green)
                    }

                    instructionsLabel
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(
                        placement: .bottomBar
                    ) {
                        Button(action: {
                            pointSemantics.removeLast()
                        }) {
                            Image(
                                systemName: "arrow.uturn.backward"
                            )
                        }
                        .disabled(pointSemantics.isEmpty)
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Spacer()
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            viewStore.send(
                                .requestSegmentation(
                                    SegmentationIdentifier(
                                        fileName: viewStore.fileName,
                                        pointSemantics: pointSemantics
                                    ),
                                    accessToken: viewStore.accessToken,
                                    snapshot: proxy.captureSnapshot()
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
                        .disabled(pointSemantics.isEmpty || isSegmenting(viewStore))
                    }
                }
                .fullScreenCover(
                    isPresented: Binding<Bool>(
                        get: {
                            isSegmenting(viewStore)
                        },
                        set: { _ in }
                    )
                ) {
                    TranslucentFullScreenCover(
                        snapshot: viewStore.afterSegmentationSnapshot
                    )
                }
                .onDisappear {
                    viewStore.send(.dismissSegmentation)
                }
            }
        }
    }

    @ViewBuilder private var instructionsLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                Image(systemName: "circle.fill").foregroundColor(.green)
                Text(
                    "Identify the subject you want to extract from the background. In most cases, one is sufficient. You may mark multiple times for complex subjects."
                )
                .multilineTextAlignment(.leading)
                .foregroundColor(.secondary)
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
    let snapshot: UIImage?

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
                        accessToken: "",
                        fileName: "Example.jpg",
                        image: UIImage(named: "Example", in: .module, with: nil)!,
                        segmentationResult: [:],
                        afterSegmentationSnapshot: nil
                    ),
                    reducer: EmptyReducer()
                )
            )
        }
    }
}
