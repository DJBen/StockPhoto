import Foundation
import StockPhotoFoundation
import UIKit

public struct FetchImageRequest: Equatable, Encodable {
    public let account: Account
    public let imageID: Int
    public let maskDerivation: MaskDerivation?

    public init(
        account: Account,
        imageID: Int,
        maskDerivation: MaskDerivation?
    ) {
        self.account = account
        self.imageID = imageID
        self.maskDerivation = maskDerivation
    }

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageID, forKey: .imageID)
    }
}
