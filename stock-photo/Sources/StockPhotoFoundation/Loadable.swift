import Foundation

public enum Loadable<T, ErrorType: Error> {
    case notLoaded
    case loading
    case loaded(T)
    case reloading(T)
    case failed(ErrorType)

    public var isLoading: Bool {
        switch self {
        case .loading, .reloading(_):
            return true
        default:
            return false
        }
    }

    /// Whether the loadable state is loading for the first time, without a content.
    ///
    /// This value is useful when deciding whether to display a loading visual placeholder.
    public var isInitiallyLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var value: T? {
        switch self {
        case .loaded(let value), .reloading(let value):
            return value
        default:
            return nil
        }
    }

    public var error: ErrorType? {
        switch self {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }

    public mutating func reload() {
        switch self {
        case .loaded(let value):
            self = .reloading(value)
        default:
            return
        }
    }
}

extension Loadable: Equatable where T: Equatable, ErrorType: Equatable {}
extension Loadable: Sendable where T: Sendable, ErrorType: Sendable {}

extension Loadable {
    public func map<NewContent>(_ transform: (T) -> NewContent) -> Loadable<NewContent, ErrorType> {
        switch self {
        case .notLoaded:
            return .notLoaded
        case .loading:
            return .loading
        case .loaded(let content):
            return .loaded(transform(content))
        case .reloading(let content):
            return .reloading(transform(content))
        case .failed(let error):
            return .failed(error)
        }
    }
}
