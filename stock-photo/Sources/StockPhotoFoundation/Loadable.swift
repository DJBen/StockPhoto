import Foundation

public enum Loadable<T, ErrorType: Error> {
    case notLoaded
    case loading
    case loaded(T)
    case reloading(T)
    case failed(ErrorType)

    public var isLoading: Bool {
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
}

extension Loadable: Equatable where T: Equatable, ErrorType: Equatable {}