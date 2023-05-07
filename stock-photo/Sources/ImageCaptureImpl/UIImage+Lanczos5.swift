import UIKit
import Accelerate
import ImageIO
import MobileCoreServices

extension UIImage {
    /// Resamples the image using the Lanczos5 resampling method with the specified scale factor.
     ///
     /// - Parameter scale: The scale factor to be applied to the image during resampling.
     /// - Returns: A new UIImage instance that is the result of the Lanczos5 resampling, or `nil` if the operation fails.
    func lanczos5ResampledImage(scale: CGFloat) -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }

        let scaleFloat = Float(scale)

        let format = vImage_CGImageFormat(cgImage: cgImage)!
        var sourceBuffer = try! vImage_Buffer(cgImage: cgImage, format: format)
        let destinationWidth = Int(CGFloat(sourceBuffer.width) * scale)
        let destinationHeight = Int(CGFloat(sourceBuffer.height) * scale)
        var destinationBuffer = try! vImage_Buffer(width: destinationWidth, height: destinationHeight, bitsPerPixel: format.bitsPerPixel)

        let resamplingFilter = vImageNewResamplingFilter(scaleFloat, vImage_Flags(kvImageHighQualityResampling))

        let error = vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, resamplingFilter, vImage_Flags(kvImageNoFlags))
        if error != kvImageNoError {
            fatalError("Error in vImageScale_ARGB8888: \(error)")
        }

        vImageDestroyResamplingFilter(resamplingFilter)

        let resultCGImage = try! destinationBuffer.createCGImage(format: format)
        return UIImage(cgImage: resultCGImage)
    }

    /// Resizes the image iteratively using the Lanczos5 resampling method until the size of the image (in bytes) is below the specified size limit.
    ///
    /// - Parameter sizeLimit: The size limit in bytes that the resulting image must not exceed.
    /// - Returns: A new UIImage instance that is the result of iterative Lanczos5 resampling and is below the specified size limit, or `nil` if the operation fails.
    func resizedImageBelowSizeLimit(_ sizeLimit: Int) -> UIImage? {
        var currentImage = self
        var currentSize = currentImage.pngData()?.count ?? 0

        while currentSize > sizeLimit {
            guard let resizedImage = currentImage.lanczos5ResampledImage(scale: 0.5) else {
                return nil
            }
            currentImage = resizedImage
            currentSize = currentImage.pngData()?.count ?? 0
        }

        return currentImage
    }
}
