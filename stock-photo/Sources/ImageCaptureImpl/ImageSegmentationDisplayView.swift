//
//  ImageSegmentationDisplayView.swift
//  
//
//  Created by Ben Lu on 1/17/23.
//

import ImageCapture
import SwiftUI

struct ImageSegmentationDisplayView: View {
    let capturedImage: CapturedImage
    let finalImage: UIImage?
    let segmentationMask: CVPixelBuffer?

    enum ImageViewMode {
        case cropped
        case overlay
        case original
    }

    @State var imageViewMode: ImageViewMode = .cropped

    @ViewBuilder private var imageView: some View {
        switch imageViewMode {
        case .cropped:
            Image(
                uiImage: finalImage ?? UIImage()
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
        case .overlay:
            Image(
                uiImage: capturedImage.image
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
        case .original:
            Image(
                uiImage: capturedImage.image
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
    }

    var body: some View {
        NavigationStack {
            imageView
            .toolbar {
                ToolbarItemGroup {
                    Picker(
                        selection: $imageViewMode
                    ) {
                        Text("Cropped").tag(ImageViewMode.cropped)
                        Text("Overlay").tag(ImageViewMode.overlay)
                        Text("Original").tag(ImageViewMode.original)
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}

struct ImageSegmentationDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSegmentationDisplayView(
            capturedImage: CapturedImage(id: UUID(), image: UIImage()),
            finalImage: nil,
            segmentationMask: nil
        )
    }
}
