import CoreImage
import CoreML
import CoreMLHelpers
import Dependencies
import Foundation
import ImageSegmentationClient
import UIKit

extension ImageSegmentationClient: DependencyKey {
    public static var liveValue: ImageSegmentationClient {
        ImageSegmentationClient(
            segment: { request in
                let config = MLModelConfiguration()
                let model = try ISNet_1024_1024(configuration: config)
                
                let width: CGFloat = 1024
                let height: CGFloat = 1024
                let resizedImage = request.image.resized(to: CGSize(width: height, height: height), scale: 1)
                guard let pixelBuffer = resizedImage.pixelBuffer(width: Int(width), height: Int(height)) else {
                    throw ImageSegmentationError.errorCreatingPixelBuffer
                }

                let outputPredictionImage = try model.prediction(input_1: pixelBuffer)

                let rawMask: CVPixelBuffer?
                if request.requestedContents.contains(.rawMask) {
                    rawMask = outputPredictionImage.activation_out
                } else {
                    rawMask = nil
                }

                let outputCIImage = CIImage(cvPixelBuffer: outputPredictionImage.activation_out)

                guard request.requestedContents.contains(.finalImage) else {
                    return ImageSegmentationResponse(rawMask: rawMask)
                }

                guard let maskImage = outputCIImage.removeWhitePixels(),
                      let maskBlurImage = maskImage.applyBlurEffect() else {
                    throw ImageSegmentationError.errorCompositingImage
                }

                guard let resizedCIImage = CIImage(image: resizedImage),
                      let compositedImage = resizedCIImage.composite(with: maskBlurImage) else {
                    throw ImageSegmentationError.errorCompositingImage
                }
                let finalImage = UIImage(
                    ciImage: compositedImage
                )
                .resized(
                    to: CGSize(width: request.image.size.width, height: request.image.size.height)
                )
                return ImageSegmentationResponse(
                    rawMask: rawMask,
                    finalImage: finalImage
                )
            }
        )
    }
}

extension CIImage {
    func removeWhitePixels() -> CIImage? {
        let chromaCIFilter = chromaKeyFilter()
        chromaCIFilter?.setValue(self, forKey: kCIInputImageKey)
        return chromaCIFilter?.outputImage
    }

    func composite(with mask: CIImage) -> CIImage? {
        return CIFilter(
            name: "CISourceOutCompositing",
            parameters: [
                kCIInputImageKey: self,
                kCIInputBackgroundImageKey: mask
            ]
        )?.outputImage
    }

    func applyBlurEffect() -> CIImage? {
        let context = CIContext(options: nil)
        let clampFilter = CIFilter(name: "CIAffineClamp")!
        clampFilter.setDefaults()
        clampFilter.setValue(self, forKey: kCIInputImageKey)

        guard let currentFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
        currentFilter.setValue(clampFilter.outputImage, forKey: kCIInputImageKey)
        currentFilter.setValue(2, forKey: "inputRadius")
        guard let output = currentFilter.outputImage,
              let cgimg = context.createCGImage(output, from: extent) else { return nil }

        return CIImage(cgImage: cgimg)
    }

    // modified from https://developer.apple.com/documentation/coreimage/applying_a_chroma_key_effect
    private func chromaKeyFilter() -> CIFilter? {
        let size = 64
        var cubeRGB = [Float]()

        for z in 0 ..< size {
            let blue = CGFloat(z) / CGFloat(size - 1)
            for y in 0 ..< size {
                let green = CGFloat(y) / CGFloat(size - 1)
                for x in 0 ..< size {
                    let red = CGFloat(x) / CGFloat(size - 1)
                    let brightness = getBrightness(red: red, green: green, blue: blue)
                    let alpha: CGFloat = brightness == 1 ? 0 : 1
                    cubeRGB.append(Float(red * alpha))
                    cubeRGB.append(Float(green * alpha))
                    cubeRGB.append(Float(blue * alpha))
                    cubeRGB.append(Float(alpha))
                }
            }
        }

        let data = Data(buffer: UnsafeBufferPointer(start: &cubeRGB, count: cubeRGB.count))

        let colorCubeFilter = CIFilter(
            name: "CIColorCube",
            parameters: [
                "inputCubeDimension": size,
                "inputCubeData": data
            ]
        )
        return colorCubeFilter
    }

    // modified from https://developer.apple.com/documentation/coreimage/applying_a_chroma_key_effect
    private func getBrightness(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        var brightness: CGFloat = 0
        color.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }
}
