import Foundation

public struct AuthenticateAppleRequest: Equatable, Encodable {
    public let code: String
    public let email: String?
    public let fullName: PersonNameComponents?

    public init(
        code: String,
        email: String?,
        fullName: PersonNameComponents?
    ) {
        self.code = code
        self.email = email
        self.fullName = fullName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(fullName?.givenName, forKey: .givenName)
        try container.encodeIfPresent(fullName?.familyName, forKey: .familyName)
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case email
        case givenName = "given_name"
        case familyName = "family_name"
    }
}

public struct AuthenticateAppleResponse: Equatable, Decodable {
    public let accessToken: String
    public let tokenType: String

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}
