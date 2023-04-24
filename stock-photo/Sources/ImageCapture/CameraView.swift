import AVFoundation
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController

    let shouldRunCameraSession: Bool
    let didFinishProcessingPhoto: (UIImage, AVDepthData?) -> Void

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        // MARK: CameraViewControllerDelegate
        func didFinishProcessingPhoto(_ photo: UIImage, depthData: AVDepthData?) {
            parent.didFinishProcessingPhoto(photo, depthData)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if shouldRunCameraSession {
            uiViewController.resumeSession()
        } else {
            uiViewController.pauseSession()
        }
    }
}
