import Foundation
import UIKit

public enum UploadFileUpdate: Equatable, Sendable {
    case inProgress(
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    )
    case completed(imageID: Int)
}

public struct UploadFileState: Equatable, Sendable, Identifiable {
    public let id: String
    public let image: UIImage
    public var update: UploadFileUpdate?
    public var error: SPError?

    public init(
        id: String,
        image: UIImage,
        update: UploadFileUpdate? = nil,
        error: SPError? = nil
    ) {
        self.id = id
        self.image = image
        self.update = update
        self.error = error
    }

    public var totalByteSent: Int64? {
        switch update {
        case .inProgress(_, let totalBytesSent, _):
            return totalBytesSent
        default:
            return 0
        }
    }

    public var totalBytesExpectedToSend: Int64? {
        switch update {
        case .inProgress(_, _, let totalBytesExpectedToSend):
            return totalBytesExpectedToSend
        default:
            return 0
        }
    }
}
