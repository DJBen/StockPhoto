import AVFoundation
import SwiftUI
import UIKit

public struct ImageViewerView: UIViewControllerRepresentable {
    var image: UIImage?
    var onTap: ((Int, Int) -> Void)?

    public init(
        image: UIImage? = nil,
        onTap: ((Int, Int) -> Void)? = nil
    ) {
        self.image = image
        self.onTap = onTap
    }

    public func makeUIViewController(context: Context) -> ImageViewerViewController {
        let viewController = ImageViewerViewController()
        viewController.image = image
        viewController.onTap = onTap
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ImageViewerViewController, context: Context) {
        uiViewController.image = image
        uiViewController.onTap = onTap
    }
}

public class ImageViewerViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!

    var onTap: ((Int, Int) -> Void)?

    var image: UIImage? {
        didSet {
            imageView?.image = image
            updateZoom()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateZoom()
    }

    private func updateZoom() {
        guard let image = imageView?.image else { return }
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size

        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale

        centerImage()
    }

    private func centerImage() {
        guard let imageView = imageView else { return }
        let scrollViewSize = scrollView.bounds.size
        var horizontalPadding: CGFloat = 0
        var verticalPadding: CGFloat = 0

        if imageView.frame.size.width < scrollViewSize.width {
            horizontalPadding = (scrollViewSize.width - imageView.frame.size.width) / 2
        }

        if imageView.frame.size.height < scrollViewSize.height {
            verticalPadding = (scrollViewSize.height - imageView.frame.size.height) / 2
        }

        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        scrollView.setZoomScale(scrollView.zoomScale * gesture.scale, animated: true)

        if gesture.state == .ended || gesture.state == .cancelled {
            if scrollView.zoomScale < scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            }
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scrollView)
        let currentOffset = scrollView.contentOffset

        var newOffset = CGPoint(x: currentOffset.x - translation.x, y: currentOffset.y - translation.y)

        guard let image = imageView?.image else { return }
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size

        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let aspectFillScale = max(widthScale, heightScale)

        let imageAspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = scrollViewSize.width / scrollViewSize.height

        if scrollView.zoomScale < aspectFillScale {
            if imageAspectRatio > screenAspectRatio {
                // Image is wider than the screen
                newOffset.y = currentOffset.y
                newOffset.x = min(max(newOffset.x, 0), scrollView.contentSize.width - scrollView.bounds.width)
            } else {
                // Image is taller than the screen
                newOffset.x = currentOffset.x
                newOffset.y = min(max(newOffset.y, 0), scrollView.contentSize.height - scrollView.bounds.height)
            }
        } else {
            newOffset.x = min(max(newOffset.x, 0), scrollView.contentSize.width - scrollView.bounds.width)
            newOffset.y = min(max(newOffset.y, 0), scrollView.contentSize.height - scrollView.bounds.height)
        }

        scrollView.contentOffset = newOffset
        gesture.setTranslation(.zero, in: scrollView)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let locationInScrollView = gesture.location(in: scrollView)
        let locationInImageView = scrollView.convert(locationInScrollView, to: imageView)

        guard let image = imageView.image else { return }
        let imageAspectRatioRect = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)

        if imageAspectRatioRect.contains(locationInImageView) {
            let imageX = (locationInImageView.x - imageAspectRatioRect.origin.x) * (image.size.width / imageAspectRatioRect.width)
            let imageY = (locationInImageView.y - imageAspectRatioRect.origin.y) * (image.size.height / imageAspectRatioRect.height)

            let tappedPixelX = Int(imageX)
            let tappedPixelY = Int(imageY)

            onTap?(tappedPixelX, tappedPixelY)
        }
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
