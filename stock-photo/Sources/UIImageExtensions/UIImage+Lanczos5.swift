import UIKit
import Accelerate
import ImageIO
import MobileCoreServices

extension UIImage {
    /// Resamples the image using the Lanczos5 resampling method with the specified scale factor.
     ///
     /// - Parameter scale: The scale factor to be applied to the image during resampling.
     /// - Returns: A new UIImage instance that is the result of the Lanczos5 resampling, or `nil` if the operation fails.
    public func lanczos5ResampledImage(size: CGSize) -> UIImage? {
        let cgImage = self.cgImage!

        var format = vImage_CGImageFormat(
            bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent
        )
        var sourceBuffer = vImage_Buffer()

        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }

        // Deallocate source buffer memory
        defer {
            sourceBuffer.data.deallocate()
        }

        // create a destination buffer
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)

        // Deallocate destination buffer memory
        defer {
            destData.deallocate()
        }

        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)

        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }

        // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return nil }

        // create a UIImage
        let resizedImage = destCGImage.flatMap { UIImage(cgImage: $0, scale: 0.0, orientation: self.imageOrientation) }
        return resizedImage
    }

    /// Resizes the image iteratively using the Lanczos5 resampling method until the size of the image (in bytes) is below the specified size limit.
    ///
    /// - Parameter sizeLimit: The size limit in bytes that the resulting image must not exceed.
    /// - Returns: A new UIImage instance that is the result of iterative Lanczos5 resampling and is below the specified size limit, or `nil` if the operation fails.
    public func resizedImageBelowSizeLimit(_ sizeLimit: Int) -> UIImage? {
        let currentSize = jpegData(compressionQuality: 1.0)?.count ?? 0

        if currentSize > sizeLimit {
            let factor = sqrt(Float(sizeLimit) / Float(currentSize))
            return lanczos5ResampledImage(size: CGSize(width: Int(Float(size.width) * factor), height: Int(Float(size.height) * factor)))
        } else {
            return self
        }
    }
}
