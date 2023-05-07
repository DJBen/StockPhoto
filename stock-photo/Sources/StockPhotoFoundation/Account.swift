import Foundation

public struct Account: Sendable, Equatable {
    public var accessToken: String
    public var userID: String
    public var email: String?
    public var givenName: String?
    public var familyName: String?

    public init(
        accessToken: String,
        userID: String,
        email: String? = nil,
        givenName: String? = nil,
        familyName: String? = nil
    ) {
        self.accessToken = accessToken
        self.userID = userID
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
    }
}
