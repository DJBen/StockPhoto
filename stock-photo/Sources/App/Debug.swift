import StockPhotoFoundation

public struct DebugModel: Equatable {
    public var isPresentingDebugSheet: Bool = false
    public var endpoint: Endpoint = .development
}

@dynamicMemberLookup
public struct DebugState: Equatable {
    public var model: DebugModel
    public var account: Account?

    public init(
        model: DebugModel,
        account: Account?
    ) {
        self.model = model
        self.account = account
    }

    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<DebugModel, Value>) -> Value {
        get {
            self.model[keyPath: keyPath]
        }
        set {
            self.model[keyPath: keyPath] = newValue
        }
    }
}

public enum DebugAction: Equatable {
    case setPresentDebugSheet(Bool)

    /// Make access token an invalid one, if it exists.
    ///
    /// This is useful for testing re-authentication flow.
    case renderAccessTokenInvalid

    case setEndpoint(Endpoint)
}
