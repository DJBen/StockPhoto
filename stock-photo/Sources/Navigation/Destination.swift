import ImageCapture
import StockPhotoFoundation
import UIKit

/// The navigation destination identifier
public enum StockPhotoDestination {
    case postImageCapture(CapturedImage)
    case selectedProject(Int)
}

extension StockPhotoDestination: Equatable, Hashable {}
