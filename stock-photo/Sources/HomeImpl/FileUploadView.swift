import ImageViewer
import PreviewAssets
import SwiftUI
import UIKit

struct FileUploadView: View {
    let image: UIImage
    let totalBytesSent: Int64
    let totalBytesExpectedToSend: Int64
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Spacer()

            ImageViewerView(
                image: image
            )
            
            FileProgressView(
                totalBytesSent: totalBytesSent,
                totalBytesExpectedToSend: totalBytesExpectedToSend
            )
            .padding()

            Spacer()

            Button {
                onCancel()
            } label: {
                Text("Cancel", comment: "The cancel button in file upload modal")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.bottom, 44)
    }
}

struct FileUploadView_Previews: PreviewProvider {
    static var previews: some View {
        FileUploadView(
            image: UIImage(named: "Example2", in: .previewAssets, with: nil)!,
            totalBytesSent: 30,
            totalBytesExpectedToSend: 100,
            onCancel: {}
        )
    }
}
