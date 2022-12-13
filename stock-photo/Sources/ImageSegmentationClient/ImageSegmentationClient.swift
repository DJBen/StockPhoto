import Dependencies
import Foundation
import UIKit

public struct ImageSegmentationRequest: Sendable {
    public let image: UIImage

    public init(image: UIImage) {
        self.image = image
    }
}

public struct ImageSegmentationResponse: Equatable, Sendable {
    public let finalImage: UIImage

    public init(finalImage: UIImage) {
        self.finalImage = finalImage
    }
}

public enum ImageSegmentationError: Equatable, LocalizedError, Sendable {
    case errorCreatingPixelBuffer
    case errorGeneratingPrediction
    case errorCompositingImage
}

public struct ImageSegmentationClient: Sendable {
    public var segment: @Sendable (ImageSegmentationRequest) async throws -> ImageSegmentationResponse

    public init(
        segment: @escaping @Sendable (ImageSegmentationRequest) async throws -> ImageSegmentationResponse
    ) {
        self.segment = segment
    }
}
