import AVFoundation
import ComposableArchitecture
import CoreGraphics
import UIKit

public struct ImageCaptureState: Equatable {
    public var accessToken: String?
    public var capturedImage: CapturedImage?
    public var finalImage: UIImage?
    public var segmentationMask: CVPixelBuffer?

    public init(
        accessToken: String? = nil,
        capturedImage: CapturedImage? = nil,
        finalImage: UIImage? = nil,
        segmentationMask: CVPixelBuffer? = nil
    ) {
        self.accessToken = accessToken
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
