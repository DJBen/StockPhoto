import UIKit

public struct ProjectImages: Sendable, Equatable {
    public let image: UIImage
    public let maskedImage: UIImage?

    public init(image: UIImage, maskedImage: UIImage?) {
        self.image = image
        self.maskedImage = maskedImage
    }

    public static func ==(lhs: ProjectImages, rhs: ProjectImages) -> Bool {
        return true
    }
}
