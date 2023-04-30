import Home
import Segmentation
import StockPhotoFoundation
import UIKit

extension SegmentationState {
    static func projectToHomeState(
        id: String,
        imageLoadable: Loadable<UIImage, SPError>?
    ) -> (_ homeState: HomeState) -> SegmentationState? {
        { homeState in
            guard let image = imageLoadable?.value else {
                return nil
            }
            return SegmentationState(
                fileID: id,
                image: image,
                segmentationResult: homeState.segmentationResult
            )
        }
    }

    func apply(_ homeState: inout HomeState) {
        // TODO
    }
}
