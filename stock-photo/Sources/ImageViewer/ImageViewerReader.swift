import SwiftUI
import UIKit

public class ImageViewerProxy: ObservableObject {
    weak var view: UIView?

    @MainActor
    public func captureSnapshot() -> UIImage? {
        guard let view = view else {
            return nil
        }
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}

/// A reader of the `ImageViewerView`, revealing an API to snapshot its current view as an image.
public struct ImageViewerReader<Content> : View where Content : View {
    @StateObject private var proxy = ImageViewerProxy()

    /// The view builder that creates the reader's content.
    public var content: (ImageViewerProxy) -> Content

    public init(@ViewBuilder content: @escaping (ImageViewerProxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(
            proxy
        )
        .imageViewerProxy(proxy)
    }
}

struct ImageViewerProxyEnvironmentKey: EnvironmentKey {
    public static var defaultValue: ImageViewerProxy? = nil
}

extension EnvironmentValues {
    var imageViewerProxy: ImageViewerProxy? {
        get { self[ImageViewerProxyEnvironmentKey.self] }
        set { self[ImageViewerProxyEnvironmentKey.self] = newValue }
    }
}

extension View {
    func imageViewerProxy(_ value: ImageViewerProxy?) -> some View {
        environment(\.imageViewerProxy, value)
    }
}
