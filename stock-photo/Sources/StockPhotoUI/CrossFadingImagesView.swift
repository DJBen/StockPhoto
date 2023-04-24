import Dependencies
import SwiftUI

@resultBuilder
public struct ImageListBuilder {
    public static func buildBlock(_ components: Image...) -> [Image] {
        components
    }
}

public struct CrossFadingImagesView: View {
    struct ImageWrapper: Identifiable {
        let id: Int
        let image: Image
    }

    @State private var currentImageIndex = 0
    let images: [ImageWrapper]
    let interval: TimeInterval

    init(interval: TimeInterval = 1.0, @ImageListBuilder _ content: () -> [Image]) {
        self.images = content().enumerated().map { ImageWrapper(id: $0, image: $1) }
        self.interval = interval
    }

    public var body: some View {
        ZStack {
            ForEach(images) { imageWrapper in
                imageWrapper.image.resizable(
                )
                .aspectRatio(contentMode: .fill)
                .opacity(currentImageIndex == imageWrapper.id ? 1.0 : 0.0)
                .animation(.easeInOut(duration: interval), value: currentImageIndex)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                currentImageIndex = (currentImageIndex + 1) % images.count
            }
        }
    }
}
