import Dependencies
@preconcurrency import KeychainAccess

private enum KeychainKey: DependencyKey {
  static let liveValue = Keychain(service: "sihao.DJBen.StockPhoto")
}

extension DependencyValues {
    var keychain: Keychain {
        get { self[KeychainKey.self] }
        set { self[KeychainKey.self] = newValue }
    }
}
