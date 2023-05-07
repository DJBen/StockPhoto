import Foundation

public struct FetchImageRequest: Equatable, Encodable {
    public let accessToken: String
    public let imageID: Int

    public init(
        accessToken: String,
        imageID: Int
    ) {
        self.accessToken = accessToken
        self.imageID = imageID
    }
}
