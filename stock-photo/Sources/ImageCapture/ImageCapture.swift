import AVFoundation
import ComposableArchitecture
import CoreGraphics
import UIKit

public struct ImageCaptureState: Equatable {
    public var capturedImage: CapturedImage?
    public var finalImage: UIImage?
    public var segmentationMask: CVPixelBuffer?

    public init(
        capturedImage: CapturedImage? = nil,
        finalImage: UIImage? = nil,
        segmentationMask: CVPixelBuffer? = nil
    ) {
        self.capturedImage = capturedImage
        self.finalImage = finalImage
        self.segmentationMask = segmentationMask
    }
}

public enum ImageCaptureAction: Equatable {
    case didCaptureImage(CapturedImage)
    case postCapture(PostImageCaptureAction)
    case dismissPostImageCapture
}
