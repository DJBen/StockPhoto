public struct DebugModel: Equatable {
    public var isPresentingDebugSheet: Bool = false
}

@dynamicMemberLookup
public struct DebugState: Equatable {
    public var model: DebugModel
    public var accessToken: String?

    public init(
        model: DebugModel,
        accessToken: String?
    ) {
        self.model = model
        self.accessToken = accessToken
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
    case wreckAccessToken
}
