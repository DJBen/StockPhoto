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
            return NSLocalizedString("NetworkError.BadRequest", value: "Bad request", comment: "Bad request")
        case .unauthorized:
            return NSLocalizedString("NetworkError.Unauthorized", value: "Unauthorized", comment: "Unauthorized")
        case .forbidden:
            return NSLocalizedString("NetworkError.Forbidden", value: "Forbidden", comment: "Forbidden")
        case .notFound:
            return NSLocalizedString("NetworkError.NotFound", value: "Not found", comment: "Not found")
        case .internalServerError:
            return NSLocalizedString("NetworkError.InternalServerError", value: "Internal server error", comment: "Internal server error")
        case .unknownError:
            return NSLocalizedString("NetworkError.UnknownError", value: "Unknown error", comment: "Unknown error")
        }
    }
}
