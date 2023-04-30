import Foundation
import Home

public struct FetchImageRequest: Equatable, Encodable {
    public let accessToken: String
    public let fileName: String

    public init(
        accessToken: String,
        fileName: String
    ) {
        self.accessToken = accessToken
        self.fileName = fileName
    }
}
