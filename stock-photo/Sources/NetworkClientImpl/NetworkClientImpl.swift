import Dependencies
import Foundation
import NetworkClient

extension NetworkClient: DependencyKey {
    public static let baseURL = "https://djben--sam-fastapi-app-dev.modal.run"
    public static let authenticateGoogleEndpoint = "\(baseURL)/auth/google"
    public static let authenticateAppleEndpoint = "\(baseURL)/auth/apple"

    public static var liveValue = NetworkClient(
        authenticateGoogle: { request in
            guard var urlComponents = URLComponents(string: authenticateGoogleEndpoint) else {
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
            guard var urlComponents = URLComponents(string: authenticateAppleEndpoint) else {
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
        },
        uploadImage: { request in
            AsyncThrowingStream { (continuation: AsyncThrowingStream<UploadFileUpdate, Error>.Continuation) in

                let url = URL(string: "/image", relativeTo: URL(string: baseURL)!)!
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("Bearer \(request.accessToken)", forHTTPHeaderField: "Authorization")

                let boundary = UUID().uuidString
                let contentType = "multipart/form-data; boundary=\(boundary)"
                urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

                let httpBody = createMultipartData(for: request, boundary: boundary)
                urlRequest.httpBody = httpBody

                let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                    if let error = error {
                        continuation.finish(throwing: error)
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        do {
                            try handleHTTPError(statusCode: httpResponse.statusCode)
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    } else if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let uploadResponse = try decoder.decode(UploadImageResponse.self, from: data)
                            continuation.yield(.completed(uploadResponse))
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    } else {
                        let unknownError = NSError(domain: "com.example.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                        continuation.finish(throwing: unknownError)
                    }
                }

                let progress = task.progress
                progress.completedUnitCount = 0

                DispatchQueue.global(qos: .background).async {
                    while !progress.isFinished && !progress.isCancelled {
                        let update = UploadFileUpdate.inProgress(bytesSent: progress.completedUnitCount, totalBytesSent: progress.completedUnitCount, totalBytesExpectedToSend: progress.totalUnitCount)
                        continuation.yield(update)
                        Thread.sleep(forTimeInterval: 0.5)
                    }
                }

                task.resume()

                continuation.onTermination = { @Sendable termination in
                    task.cancel()
                }
            }
        }
    )

    private static func createMultipartData(for request: UploadImageRequest, boundary: String) -> Data {
        var body = Data()

        let boundaryPrefix = "--\(boundary)\r\n"

        // Add image
        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"image\"; filename=\"\(request.fileName)\"\r\n")
        body.append(string: "Content-Type: image/jpeg\r\n\r\n")
        body.append(request.image)
        body.append(string: "\r\n")

        // Add file name
        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"file_name\"\r\n\r\n")
        body.append(string: request.fileName)
        body.append(string: "\r\n")

        // Add overwrite
        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"overwrite\"\r\n\r\n")
        body.append(string: "\(request.overwrite)")
        body.append(string: "\r\n")

        body.append(string: "--\(boundary)--")

        return body
    }

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

extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
