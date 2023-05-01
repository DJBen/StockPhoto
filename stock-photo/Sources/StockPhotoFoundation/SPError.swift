import Foundation

public enum SPError: LocalizedError {
    case httpError(HTTPError)
    case unparsableImageData
    case emptyTransferredImage
    case unknownError(Error)

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

    public static func `catch`(_ error: Error) -> SPError {
        if let spError = error as? SPError {
            return spError
        }
        return .unknownError(error)
    }
}

extension SPError: Equatable {
    public static func == (lhs: SPError, rhs: SPError) -> Bool {
        switch (lhs, rhs) {
        case (.httpError(let lhsError), .httpError(let rhsError)):
            return lhsError == rhsError
        case (.unparsableImageData, .unparsableImageData):
            return true
        case (.emptyTransferredImage, .emptyTransferredImage):
            return true
        case (.unknownError(let lhsError), .unknownError(let rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        default:
            return false
        }
    }
}
