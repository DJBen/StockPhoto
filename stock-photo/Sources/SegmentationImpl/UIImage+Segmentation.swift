import UIKit

extension UIImage {
    static func renderMaskedImage(from rleData: [Int], color: UIColor, width: Int, height: Int) -> UIImage? {
        // Create Core Graphics context
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Decode RLE data and draw the mask
        var index = 0
        var currentValue: UInt8 = 0
        for runLength in rleData {
            for _ in 0..<runLength {
                let row = index / height
                let col = index % height
                if currentValue == 1 {
                    context.setFillColor(color.cgColor)
                    context.fill(CGRect(x: col, y: row, width: 1, height: 1))
                }
                index += 1
            }
            currentValue = currentValue == 1 ? 0 : 1
        }

        // Create UIImage from context
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return maskedImage
    }

    func croppedImage(using rleData: [Int]) -> UIImage? {
        guard let inputCGImage = cgImage else { return nil }
        let (width, height) = (Int(size.width), Int(size.height))

        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Flip the coordinate system
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // Draw the original image
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Decode RLE data and crop the image where the mask is 1
        var index = 0
        var currentValue: UInt8 = 0
        for runLength in rleData {
            for _ in 0..<runLength {
                let col = index / height
                let row = height - 1 - (index % height) // Adjust the row calculation to account for vertical mirroring
                if currentValue == 0 {
                    context.clear(CGRect(x: col, y: row, width: 1, height: 1))
                }
                index += 1
            }
            currentValue = currentValue == 1 ? 0 : 1
        }

        // Create UIImage from context
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return croppedImage
    }
}
