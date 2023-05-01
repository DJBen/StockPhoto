import AVFoundation
import SwiftUI
import UIKit

/// A SwiftUI wrapper for `ImageViewerViewController`, allowing you to display an image with pinch-to-zoom and panning functionality.
///
/// The `ImageViewerView` can be initialized with an optional `UIImage` and a closure that is called when a tap occurs on the image.
/// The closure is passed the tapped pixel's (x, y) coordinates as its parameters.
public struct ImageViewerView<Overlay: View>: UIViewControllerRepresentable {
    @Environment(\.imageViewerProxy) private var proxy

    /// The image to be displayed in the view.
    var image: UIImage?

    /// A closure that is called when the image is tapped, passing the tapped pixel's (x, y) coordinates.
    var onTap: ((Int, Int) -> Void)?

    /// The overlay view that is displayed on top of the image.
    var overlay: () -> Overlay

    /// Initializes a new instance of the `ImageViewerView` with the provided image, a tap handler and an overlay.
    ///
    /// - Parameters:
    ///   - image: The image to be displayed. Defaults to `nil`.
    ///   - onTap: A closure that is called when the image is tapped, passing the tapped pixel's (x, y) coordinates. Defaults to `nil`.
    ///   - overlay: An overlay SwiftUI view that is the same frame as the underlying image.
    public init(
        image: UIImage? = nil,
        onTap: ((Int, Int) -> Void)? = nil,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.image = image
        self.onTap = onTap
        self.overlay = overlay
    }

    public func makeUIViewController(context: Context) -> ImageViewerViewController {
        let viewController = ImageViewerViewController()
        viewController.image = image
        viewController.onTap = onTap
        viewController.overlay = UIHostingController(rootView: AnyView(overlay()))
        viewController.proxy = proxy
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ImageViewerViewController, context: Context) {
        uiViewController.update(
            image: image,
            onTap: onTap,
            overlay: AnyView(overlay())
        )
    }
}

public class ImageViewerViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!

    var proxy: ImageViewerProxy?

    var onTap: ((Int, Int) -> Void)?

    /// The overlay view that is displayed on top of the image.
    /// The overlay view is provided by a SwiftUI view and converted to a UIView using UIHostingController.
    /// The overlay view is the same frame as the underlying image, and its background is set to be clear.
    var overlay: UIHostingController<AnyView>? {
        didSet {
            oldValue?.view.removeFromSuperview()
            setUpOverlay()
        }
    }

    var image: UIImage? {
        didSet {
            imageView?.image = image
            updateZoom()
        }
    }

    func update(
        image: UIImage?,
        onTap: ((Int, Int) -> Void)?,
        overlay: AnyView
    ) {
        if self.image != image {
            self.image = image
        }
        self.onTap = onTap
        self.overlay?.rootView = overlay
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateZoom()
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

        setUpOverlay()

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(panGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
         doubleTapGesture.numberOfTapsRequired = 2
         imageView.isUserInteractionEnabled = true
         imageView.addGestureRecognizer(doubleTapGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        // Ensure single tap gesture only fires if double tap doesn't
        tapGesture.require(toFail: doubleTapGesture)
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)

        proxy?.view = view
    }

    private func setUpOverlay() {
        guard overlay?.view.superview == nil else {
            return
        }
        if let overlayView = overlay?.view, let imageView = imageView {
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            overlayView.backgroundColor = .clear
            imageView.addSubview(overlayView)

            NSLayoutConstraint.activate([
                overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
                overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
        }
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

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let locationInImageView = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(scrollView.maximumZoomScale, center: locationInImageView)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(width: scrollView.frame.size.width / scale,
                          height: scrollView.frame.size.height / scale)
        let origin = CGPoint(x: center.x - size.width / 2,
                             y: center.y - size.height / 2)
        return CGRect(origin: origin, size: size)
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

    private func updateZoom() {
        guard let image = imageView?.image else { return }
        let scrollViewSize = scrollView.bounds.size
        if scrollViewSize.equalTo(.zero) {
            return
        }
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

    // MARK: - ScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}

extension ImageViewerView where Overlay == EmptyView {
    /// Initializes a new instance of the `ImageViewerView` with the provided image and tap handler.
    ///
    /// - Parameters:
    ///   - image: The image to be displayed. Defaults to `nil`.
    ///   - onTap: A closure that is called when the image is tapped, passing the tapped pixel's (x, y) coordinates. Defaults to `nil`.
    public init(
        image: UIImage? = nil,
        onTap: ((Int, Int) -> Void)? = nil
    ) {
        self.image = image
        self.onTap = onTap
        self.overlay = {
            EmptyView()
        }
    }
}
