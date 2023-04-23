public struct AuthenticateGoogleRequest: Equatable, Encodable {
    public let code: String
    public let email: String?
    public let givenName: String?
    public let familyName: String?

    public init(
        code: String,
        email: String?,
        givenName: String?,
        familyName: String?
    ) {
        self.code = code
        self.email = email
        self.givenName = givenName
        self.familyName = familyName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(givenName, forKey: .givenName)
        try container.encodeIfPresent(familyName, forKey: .familyName)
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case email
        case givenName = "given_name"
        case familyName = "family_name"
    }
}

public struct AuthenticateGoogleResponse: Equatable, Decodable {
    public let accessToken: String
    public let tokenType: String

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}
