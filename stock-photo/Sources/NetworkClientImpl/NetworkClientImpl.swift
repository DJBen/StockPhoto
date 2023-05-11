import Foundation
import NetworkClient
import Nuke
import StockPhotoFoundation
import UIKit

public final class NetworkClientImpl: NSObject, Sendable {
    private static let baseURL = "https://djben--sam-fastapi-app-dev.modal.run"
//    private static let baseURL = "https://djben--sam-fastapi-app.modal.run"
    private static let authenticateGoogleEndpoint = "\(baseURL)/auth/google"
    private static let authenticateAppleEndpoint = "\(baseURL)/auth/apple"
    private static let listProjectsEndpoint = "\(baseURL)/projects"
    private static func fetchImageEndpoint(_ imageID: Int) -> String {
        return "\(baseURL)/image/\(imageID)"
    }
    private static let segmentEndpoint = "\(baseURL)/segment_image"
    private static let confirmMaskEndpoint = "\(baseURL)/confirm_mask"
    private var continuations: [Int: AsyncThrowingStream<UploadFileUpdate, Error>.Continuation] = [:]
    private let continuationQueue = DispatchQueue(label: "sihao.DJBen.StockPhoto.continuationQueue", attributes: .concurrent)

    let dataCache: DataCaching
    let imageEncoder: ImageEncoders.Default = .init()
    let imageDecoder: ImageDecoders.Default = .init()

    public init(
        dataCache: DataCaching
    ) {
        self.dataCache = dataCache
        super.init()
    }
}

extension NetworkClientImpl: NetworkClient {
    public func authenticateGoogle(_ request: AuthenticateGoogleRequest) async throws -> AuthenticateGoogleResponse {
        var urlComponents = URLComponents(string: NetworkClientImpl.authenticateGoogleEndpoint)!

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

        let url = urlComponents.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AuthenticateGoogleResponse.self, from: data)
    }

    public func authenticateApple(_ request: AuthenticateAppleRequest) async throws -> AuthenticateAppleResponse {
        var urlComponents = URLComponents(string: NetworkClientImpl.authenticateAppleEndpoint)!

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

        let url = urlComponents.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AuthenticateAppleResponse.self, from: data)
    }

    public func uploadImage(_ request: UploadImageRequest) -> AsyncThrowingStream<UploadFileUpdate, Error> {
        AsyncThrowingStream { continuation in
            let url = URL(string: "/image", relativeTo: URL(string: NetworkClientImpl.baseURL)!)!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue("Bearer \(request.account.accessToken)", forHTTPHeaderField: "Authorization")

            let boundary = UUID().uuidString
            let contentType = "multipart/form-data; boundary=\(boundary)"
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")

            let httpBody = NetworkClientImpl.createMultipartData(for: request, boundary: boundary)
            urlRequest.httpBody = httpBody

            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)

            let task = session.uploadTask(with: urlRequest, from: httpBody) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    do {
                        try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                } else if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let uploadResponse = try decoder.decode(UploadImageResponse.self, from: data)
                        continuation.yield(
                            .completed(imageID: uploadResponse.imageID)
                        )
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                } else {
                    let unknownError = NSError(domain: "com.example.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                    continuation.finish(throwing: unknownError)
                }
            }

            task.resume()

            // Store the continuation in the dictionary
            continuationQueue.async(flags: .barrier) {
                self.continuations[task.taskIdentifier] = continuation
            }

            continuation.onTermination = { @Sendable termination in
                task.cancel()
                // Remove the continuation from the dictionary when the task is terminated
                self.continuationQueue.async(flags: .barrier) {
                    self.continuations[task.taskIdentifier] = nil
                }
            }
        }
    }

    public func listProjects(_ request: ListProjectsRequest) async throws -> ListProjectsResponse {
        let urlComponents = URLComponents(string: NetworkClientImpl.listProjectsEndpoint)!
        let url = urlComponents.url!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(request.account.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ListProjectsResponse.self, from: data)
    }

    public func fetchImage(_ request: FetchImageRequest) async throws -> UIImage {
        let cacheKey = "\(request.account.userID)_\(request.imageID)"
        if dataCache.containsData(for: cacheKey), let imageData = dataCache.cachedData(for: cacheKey) {
            return try imageDecoder.decode(imageData).image
        }

        let urlComponents = URLComponents(string: NetworkClientImpl.fetchImageEndpoint(request.imageID))!
        let url = urlComponents.url!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(request.account.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw SPError.unparsableImageData
        }

        if let encodedImageData = imageEncoder.encode(image) {
            dataCache.storeData(encodedImageData, for: cacheKey)
        }

        return image
    }

    public func segment(_ request: SegmentRequest) async throws -> SegmentResponse {
        let urlComponents = URLComponents(string: NetworkClientImpl.segmentEndpoint)!
        let url = urlComponents.url!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(request.account.accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonEncoder = JSONEncoder()
        urlRequest.httpBody = try jsonEncoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SegmentResponse.self, from: data)
    }

    public func confirmMask(_ request: ConfirmMaskRequest) async throws -> ConfirmMaskResponse {
        let urlComponents = URLComponents(string: NetworkClientImpl.confirmMaskEndpoint)!
        let url = urlComponents.url!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(request.account.accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonEncoder = JSONEncoder()
        urlRequest.httpBody = try jsonEncoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            try NetworkClientImpl.handleHTTPError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ConfirmMaskResponse.self, from: data)
    }

    private static func createMultipartData(for request: UploadImageRequest, boundary: String) -> Data {
        var body = Data()

        let boundaryPrefix = "--\(boundary)\r\n"

        // Add image
        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"image\"; filename=\"image\"\r\n")
        body.append(string: "Content-Type: \(request.mimeType)\r\n\r\n")
        body.append(request.image)
        body.append(string: "\r\n")

        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"is_test\"\r\n\r\n")
        body.append(string: "\(true)")
        body.append(string: "\r\n")

        body.append(string: "--\(boundary)--")

        return body
    }

    private static func handleHTTPError(statusCode: Int) throws {
        switch statusCode {
        case 400:
            throw HTTPError.badRequest
        case 401:
            throw HTTPError.unauthorized
        case 403:
            throw HTTPError.forbidden
        case 404:
            throw HTTPError.notFound
        case 500:
            throw HTTPError.internalServerError
        default:
            throw HTTPError.unknownError
        }
    }
}

extension NetworkClientImpl: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        continuationQueue.sync {
            if let continuation = continuations[task.taskIdentifier] {
                let update = UploadFileUpdate.inProgress(bytesSent: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
                continuation.yield(update)
            }
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
