import UIKit

extension UIImage {
    /// Fixes the orientation of the image before uploading, after loading from the camera roll.
    /// - SeeAlso: https://stackoverflow.com/a/45476420/1085698
    public func fixingImageOrientation() -> UIImage {
        UIGraphicsBeginImageContext(size)
        draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
