/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's photo capture delegate object.
*/

import AVFoundation
import Photos
import UIKit

class PhotoCaptureProcessor: NSObject {
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings

    private let willCapturePhotoAnimation: () -> Void

    private let completionHandler: (PhotoCaptureProcessor) -> Void

    private let photoProcessingHandler: (Bool) -> Void

    private var portraitEffectsMatteData: Data?

    private var semanticSegmentationMatteDataArray = [Data]()

    private var maxPhotoProcessingTime: CMTime?

    private weak var cameraViewDelegate: CameraViewControllerDelegate?

    lazy var context = CIContext()

    // Save the location of captured photos
    var location: CLLocation?

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         cameraViewDelegate: CameraViewControllerDelegate?,
         willCapturePhotoAnimation: @escaping () -> Void,
         completionHandler: @escaping (PhotoCaptureProcessor) -> Void,
         photoProcessingHandler: @escaping (Bool) -> Void) {
        self.cameraViewDelegate = cameraViewDelegate
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    /*
     This extension adopts all of the AVCapturePhotoCaptureDelegate protocol methods.
     */

    /// - Tag: WillBeginCapture
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
    }

    /// - Tag: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()

        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }

        // Show a spinner if processing time exceeds one second.
        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            photoProcessingHandler(true)
        }
    }

    func handleMatteData(_ photo: AVCapturePhoto, ssmType: AVSemanticSegmentationMatte.MatteType) {
        // Find the semantic segmentation matte image for the specified type.
        guard var segmentationMatte = photo.semanticSegmentationMatte(
            for: ssmType
        ) else {
            return
        }

        // Retrieve the photo orientation and apply it to the matte image.
        if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
            // Apply the Exif orientation to the matte image.
            segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
        }

        var imageOption: CIImageOption!

        // Switch on the AVSemanticSegmentationMatteType value.
        switch ssmType {
        case .hair:
            imageOption = .auxiliarySemanticSegmentationHairMatte
        case .skin:
            imageOption = .auxiliarySemanticSegmentationSkinMatte
        case .teeth:
            imageOption = .auxiliarySemanticSegmentationTeethMatte
        case .glasses:
            imageOption = .auxiliarySemanticSegmentationGlassesMatte
        default:
            print("This semantic segmentation type is not supported!")
            return
        }

        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }

        // Create a new CIImage from the matte's underlying CVPixelBuffer.
        let ciImage = CIImage(
            cvImageBuffer: segmentationMatte.mattingImage,
            options: [
                imageOption: true,
                .colorSpace: perceptualColorSpace
            ]
        )

        // Get the HEIF representation of this image.
        guard let imageData = context.heifRepresentation(
            of: ciImage,
            format: .RGBA8,
            colorSpace: perceptualColorSpace,
            options: [.depthImage: ciImage]
        ) else {
            return
        }

        // Add the image data to the SSM data array for writing to the photo library.
        semanticSegmentationMatteDataArray.append(imageData)
    }

    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        photoProcessingHandler(false)

        if let error = error {
            print("Error capturing photo: \(error)")
            return
        } else {
            if let imageFileRepresentation = photo.fileDataRepresentation(), let image = UIImage(data: imageFileRepresentation) {
                cameraViewDelegate?.didFinishProcessingPhoto(
                    image,
                    depthData: photo.depthData
                )
            }
        }
        // A portrait effects matte gets generated only if AVFoundation detects a face.
        if var portraitEffectsMatte = photo.portraitEffectsMatte {
            if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32 {
                portraitEffectsMatte = portraitEffectsMatte.applyingExifOrientation(CGImagePropertyOrientation(rawValue: orientation)!)
            }
            let portraitEffectsMattePixelBuffer = portraitEffectsMatte.mattingImage
            let portraitEffectsMatteImage = CIImage(
                cvImageBuffer: portraitEffectsMattePixelBuffer,
                options: [.auxiliaryPortraitEffectsMatte: true]
            )

            guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
                portraitEffectsMatteData = nil
                return
            }
            portraitEffectsMatteData = context.heifRepresentation(
                of: portraitEffectsMatteImage,
                format: .RGBA8,
                colorSpace: perceptualColorSpace,
                options: [.portraitEffectsMatteImage: portraitEffectsMatteImage]
            )
        } else {
            portraitEffectsMatteData = nil
        }

        for semanticSegmentationType in output.enabledSemanticSegmentationMatteTypes {
            handleMatteData(photo, ssmType: semanticSegmentationType)
        }
    }

    /// - Tag: DidFinishCapture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completionHandler(self)
            return
        }
    }
}
