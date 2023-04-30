import ComposableArchitecture
import ImageCapture
import ImageViewer
import SwiftUI

struct PostImageCaptureView: View {
    let store: StoreOf<PostImageCapture>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack(alignment: .topLeading) {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    ImageViewerView(
                        image: viewStore.capturedImage.image
                    )
                    Button(action: {
                        viewStore.send(.uploadImage)
                    }) {
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text("Proceed to segment magic")
                                .font(.headline)
                            Text("The image will be uploaded to our server to be processed for magical segmentation and creations.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .systemGreen))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                HStack {
                    Button(
                        role: .destructive
                    ) {
                        viewStore.send(.retakeImage)
                    } label: {
                        Text(
                            viewStore.buttonText.text
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

extension PostImageCaptureButtonText {
    var text: String {
        switch self {
        case .retake:
            return "Retake"
        case .chooseAnother:
            return "Choose Another"
        }
    }
}

struct PostImageCapture_Previews: PreviewProvider {
    static var previews: some View {
        PostImageCaptureView(
            store: Store(
                initialState: PostImageCapture.State(
                    capturedImage: CapturedImage(
                        id: UUID(),
                        image: UIImage(named: "Example2", in: .module, with: nil)!
                    ),
                    buttonText: .retake
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
