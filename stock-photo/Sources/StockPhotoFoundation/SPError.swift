import Foundation

public enum SPError: LocalizedError {
    case httpError(HTTPError)
    case unparsableImageData
    case emptyTransferredImage
    case unknownError(Error)

    public var title: String {
        switch self {
        case .httpError:
            return NSLocalizedString(
                "SPError.httpError.title",
                value: "Network error",
                comment: "The title of a network error"
            )
        default:
            return NSLocalizedString(
                "SPError.otherErrors.title",
                value: "Oops",
                comment: "The title of errors other than network errors"
            )
        }
    }

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
        case .unknownError(let error):
            return error.localizedDescription
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .httpError(let httpError):
            return httpError.recoverySuggestion
        case .unparsableImageData:
            return NSLocalizedString(
                "SPError.unparsableImageData.recoverySuggestion",
                value: "You may try to delete and reupload the image",
                comment: "Happens when we fail to parse the downloaded image data"
            )
        case .emptyTransferredImage:
            return NSLocalizedString(
                "SPError.emptyTransferredImage.recoverySuggestion",
                value: "Please select your image again",
                comment: "Happens when we fail to parse the downloaded image data"
            )
        case .unknownError(let error):
            if let localizedError = error as? LocalizedError {
                return localizedError.recoverySuggestion
            }
            return NSLocalizedString(
                "SPError.unknownError.unknownError",
                value: "Please try again",
                comment: "An unknown error"
            )
        }
    }

    public static func `catch`(_ error: Error) -> SPError {
        if let spError = error as? SPError {
            return spError
        } else if let httpError = error as? HTTPError {
            return .httpError(httpError)
        }
        return .unknownError(error)
    }

    public var isUnauthorizedError: Bool {
        switch self {
        case .httpError(let httpError):
            return httpError == .unauthorized
        default:
            return false
        }
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
