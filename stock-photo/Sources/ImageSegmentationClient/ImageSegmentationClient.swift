import Dependencies
import Foundation
import UIKit

public struct ImageSegmentationRequest: Sendable {
    public struct RequestedContents: OptionSet, Sendable {
        public let rawValue: UInt

        public static let rawMask = RequestedContents(rawValue: 1 << 0)
        public static let finalImage = RequestedContents(rawValue: 1 << 1)
        public static let all: RequestedContents = [.rawMask, .finalImage]

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }

    public let image: UIImage
    public let requestedContents: RequestedContents

    public init(
        image: UIImage,
        requestedContents: RequestedContents
    ) {
        self.image = image
        self.requestedContents = requestedContents
    }
}

public struct ImageSegmentationResponse: Equatable {
    public let rawMask: CVPixelBuffer?
    public let finalImage: UIImage?

    public init(
        rawMask: CVPixelBuffer? = nil,
        finalImage: UIImage? = nil
    ) {
        self.rawMask = rawMask
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
