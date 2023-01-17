//
//  ImageSegmentationDisplayView.swift
//  
//
//  Created by Ben Lu on 1/17/23.
//

import ImageCaptureCore
import SwiftUI

struct ImageSegmentationDisplayView: View {
    let capturedImage: CapturedImage

    var body: some View {
        Image(
            uiImage: capturedImage.image
        )
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
}

struct ImageSegmentationDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSegmentationDisplayView(
            capturedImage: CapturedImage(id: UUID(), image: UIImage())
        )
    }
}
