import Foundation

enum NetworkError: LocalizedError {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case internalServerError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .badRequest:
            return NSLocalizedString("NetworkError.BadRequest.description", value: "There was a problem with the request.", comment: "Bad request")
        case .unauthorized:
            return NSLocalizedString("NetworkError.Unauthorized.description", value: "You don't have permission to access this.", comment: "Unauthorized")
        case .forbidden:
            return NSLocalizedString("NetworkError.Forbidden.description", value: "Access to this resource is not allowed.", comment: "Forbidden")
        case .notFound:
            return NSLocalizedString("NetworkError.NotFound.description", value: "The requested item could not be found.", comment: "Not found")
        case .internalServerError:
            return NSLocalizedString("NetworkError.InternalServerError.description", value: "There was a problem on our end. We're working to fix it.", comment: "Internal server error")
        case .unknownError:
            return NSLocalizedString("NetworkError.UnknownError.description", value: "An unexpected error occurred.", comment: "Unknown error")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .badRequest:
            return NSLocalizedString("NetworkError.BadRequest.Recovery", value: "Please check your input and try again.", comment: "Bad request recovery")
        case .unauthorized:
            return NSLocalizedString("NetworkError.Unauthorized.Recovery", value: "Make sure you're logged in and have the right permissions.", comment: "Unauthorized recovery")
        case .forbidden:
            return NSLocalizedString("NetworkError.Forbidden.Recovery", value: "Contact support if you believe you should have access.", comment: "Forbidden recovery")
        case .notFound:
            return NSLocalizedString("NetworkError.NotFound.Recovery", value: "Double-check the URL or try a different search.", comment: "Not found recovery")
        case .internalServerError:
            return NSLocalizedString("NetworkError.InternalServerError.Recovery", value: "Please try again later.", comment: "Internal server error recovery")
        case .unknownError:
            return NSLocalizedString("NetworkError.UnknownError.Recovery", value: "If the problem persists, contact support.", comment: "Unknown error recovery")
        }
    }
}
