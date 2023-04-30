import ImageCapture
import Home
import Foundation
import UIKit

/// The navigation destination identifier
public enum StockPhotoDestination {
    case postImageCapture(CapturedImage)
    case selectedImageProject(String)
}

extension StockPhotoDestination: Equatable, Hashable {}