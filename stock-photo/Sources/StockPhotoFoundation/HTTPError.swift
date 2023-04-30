import Foundation

public enum HTTPError: LocalizedError, Equatable {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case internalServerError
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .badRequest:
            return NSLocalizedString("HTTPError.BadRequest.description", value: "There was a problem with the request.", comment: "Bad request")
        case .unauthorized:
            return NSLocalizedString("HTTPError.Unauthorized.description", value: "You don't have permission to access this.", comment: "Unauthorized")
        case .forbidden:
            return NSLocalizedString("HTTPError.Forbidden.description", value: "Access to this resource is not allowed.", comment: "Forbidden")
        case .notFound:
            return NSLocalizedString("HTTPError.NotFound.description", value: "The requested item could not be found.", comment: "Not found")
        case .internalServerError:
            return NSLocalizedString("HTTPError.InternalServerError.description", value: "There was a problem on our end. We're working to fix it.", comment: "Internal server error")
        case .unknownError:
            return NSLocalizedString("HTTPError.UnknownError.description", value: "An unexpected error occurred.", comment: "Unknown error")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .badRequest:
            return NSLocalizedString("HTTPError.BadRequest.Recovery", value: "Please check your input and try again.", comment: "Bad request recovery")
        case .unauthorized:
            return NSLocalizedString("HTTPError.Unauthorized.Recovery", value: "Make sure you're logged in and have the right permissions.", comment: "Unauthorized recovery")
        case .forbidden:
            return NSLocalizedString("HTTPError.Forbidden.Recovery", value: "Contact support if you believe you should have access.", comment: "Forbidden recovery")
        case .notFound:
            return NSLocalizedString("HTTPError.NotFound.Recovery", value: "Double-check the URL or try a different search.", comment: "Not found recovery")
        case .internalServerError:
            return NSLocalizedString("HTTPError.InternalServerError.Recovery", value: "Please try again later.", comment: "Internal server error recovery")
        case .unknownError:
            return NSLocalizedString("HTTPError.UnknownError.Recovery", value: "If the problem persists, contact support.", comment: "Unknown error recovery")
        }
    }
}
