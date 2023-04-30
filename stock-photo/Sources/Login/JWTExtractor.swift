import Dependencies
import Foundation

public struct JWTExtractor: Sendable {
    /**
     Extracts the `sub` (subject) claim from a JSON Web Token (JWT) string.

     This method takes a JWT token string as input and extracts the `sub` claim from its payload. The `sub` claim usually represents the user identifier in a JWT token.

     - Parameter jwtToken: The JWT token string to extract the `sub` claim from.
     - Returns: The `sub` claim value as a `String`.
     - Throws: An `NSError` with a localized description if the JWT token is invalid, the base64 encoding is invalid, or the `sub` claim is not found in the token.

     - Precondition:
        - `jwtToken` must be a valid JWT token string with three components separated by dots (.).

     - Postcondition:
        - The returned `String` contains the extracted `sub` claim value.

     Example usage:
      ```swift
        do {
            let jwtToken = "your.jwt.token.string"
            let sub = try extractSubFromJWT(jwtToken)
            print("User ID: \(sub)")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
     ```
     */
    public func extractSubFromJWT(_ jwtToken: String) throws -> String {
        func constructError(_ localizedDescription: String) -> Error {
            NSError(
                domain: "JWTToken",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: localizedDescription
                ]
            )
        }

        let tokenComponents = jwtToken.components(separatedBy: ".")

        guard tokenComponents.count == 3 else {
            throw constructError("Invalid JWT token")
        }

        let payloadBase64Url = tokenComponents[1]
        let payloadBase64 = payloadBase64Url.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let missingPadding = payloadBase64.count % 4
        let padding = missingPadding > 0 ? String(repeating: "=", count: 4 - missingPadding) : ""

        guard let payloadData = Data(base64Encoded: payloadBase64 + padding) else {
            throw constructError("Invalid base64 encoding")
        }

        if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any], let sub = json["sub"] as? String {
            return sub
        } else {
            throw constructError("User not found in JWT token")
        }
    }
}

extension JWTExtractor: DependencyKey {
    public static let liveValue = JWTExtractor()
}

extension DependencyValues {
    public var jwtExtractor: JWTExtractor {
        get { self[JWTExtractor.self] }
        set { self[JWTExtractor.self] = newValue }
    }
}
