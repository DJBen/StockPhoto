import Dependencies
import Foundation
import NetworkClient

extension NetworkClient: DependencyKey {
    public static var liveValue = NetworkClient(
        authenticateGoogle: { request in
            guard var urlComponents = URLComponents(string: "https://djben--sam-fastapi-app-dev.modal.run/auth/google") else {
                throw NSError(domain: "URLComponentsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create URLComponents"])
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "code", value: request.code)
            ]

            if let email = request.email {
                urlComponents.queryItems?.append(URLQueryItem(name: "email", value: email))
            }

            if let givenName = request.givenName {
                urlComponents.queryItems?.append(URLQueryItem(name: "given_name", value: givenName))
            }

            if let familyName = request.familyName {
                urlComponents.queryItems?.append(URLQueryItem(name: "family_name", value: familyName))
            }

            guard let url = urlComponents.url else {
                throw NSError(domain: "URLError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                try handleHTTPError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(AuthenticateGoogleResponse.self, from: data)
        },
        authenticateApple: { request in
            guard var urlComponents = URLComponents(string: "https://djben--sam-fastapi-app-dev.modal.run/auth/apple") else {
                throw NSError(domain: "URLComponentsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create URLComponents"])
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "code", value: request.code)
            ]

            if let email = request.email {
                urlComponents.queryItems?.append(URLQueryItem(name: "email", value: email))
            }

            if let givenName = request.fullName?.givenName {
                urlComponents.queryItems?.append(URLQueryItem(name: "given_name", value: givenName))
            }

            if let familyName = request.fullName?.familyName {
                urlComponents.queryItems?.append(URLQueryItem(name: "family_name", value: familyName))
            }

            guard let url = urlComponents.url else {
                throw NSError(domain: "URLError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create URL"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                try handleHTTPError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(AuthenticateAppleResponse.self, from: data)
        }
    )

    private static func handleHTTPError(statusCode: Int) throws {
        switch statusCode {
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500:
            throw NetworkError.internalServerError
        default:
            throw NetworkError.unknownError
        }
    }
}
