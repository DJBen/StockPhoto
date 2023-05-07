import Foundation

public struct Project: Sendable, Equatable, Identifiable, Decodable {
    public var image: ImageDescriptor
    public var maskDerivation: MaskDerivation?

    public var id: Int {
        image.id
    }

    public init(
        image: ImageDescriptor,
        maskDerivation: MaskDerivation?
    ) {
        self.image = image
        self.maskDerivation = maskDerivation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.image = try container.decode(ImageDescriptor.self, forKey: .image)
        self.maskDerivation = try container.decodeIfPresent(MaskDerivation.self, forKey: .maskDerivation)
    }

    private enum CodingKeys: String, CodingKey {
        case image
        case maskDerivation = "mask_derivation"
    }
}
