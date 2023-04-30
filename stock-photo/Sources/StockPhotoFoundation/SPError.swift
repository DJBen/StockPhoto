import Foundation

public enum SPError: LocalizedError, Equatable {
    case httpError(HTTPError)
    case unparsableImageData
    case emptyTransferredImage
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .httpError(let httpError):
            return httpError.errorDescription
        case .unparsableImageData:
            return NSLocalizedString(
                "SPError.unparsableImageData.description",
                value: "The image data may be corrupted.",
                comment: "Happens when we fail to parse the downloaded image data"
            )
        case .emptyTransferredImage:
            return NSLocalizedString(
                "SPError.emptyTransferredImage.description",
                value: "We can't load your image",
                comment: "Happens when we loading from image gallery yield empty result"
            )
        case .unknownError:
            return NSLocalizedString(
                "SPError.emptyTransferredImage.unknownError",
                value: "An unknown error occurred",
                comment: "An unknown error"
            )
        }
    }
}
