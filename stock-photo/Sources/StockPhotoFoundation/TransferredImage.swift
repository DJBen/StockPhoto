import Foundation
import UniformTypeIdentifiers

public struct TransferredImage: Equatable, Sendable {
    public let imageData: Data
    public let mimeType: UTType

    public init(imageData: Data, mimeType: UTType) {
        self.imageData = imageData
        self.mimeType = mimeType
    }
}
