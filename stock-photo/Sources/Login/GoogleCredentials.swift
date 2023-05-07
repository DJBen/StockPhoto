import Foundation

public struct GoogleCredentials: Equatable, Sendable {
    public let code: String
    public let email: String?
    public let givenName: String?
    public let familyName: String?

    public init(code: String, email: String? = nil, givenName: String? = nil, familyName: String? = nil) {
        self.code = code
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
    }
}
