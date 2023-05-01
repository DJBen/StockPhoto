import Home
import Segmentation
import StockPhotoFoundation
import UIKit

extension SegmentationState {
    static func projectToHomeState(
        fileName: String,
        imageLoadable: Loadable<UIImage, SPError>?,
        imageProjects: Loadable<[ImageProject], SPError>
    ) -> (_ homeState: HomeState) -> SegmentationState? {
        { homeState in
            guard let image = imageLoadable?.value else {
                return nil
            }
            guard let imageProject = imageProjects.value?.first(where: { $0.imageFile == fileName }) else {
                return nil
            }
            guard let accessToken = homeState.accessToken else {
                return nil
            }
            return SegmentationState(
                accessToken: accessToken,
                fileName: imageProject.imageFile,
                image: image,
                segmentationResult: homeState.segmentationResult,
                afterSegmentationSnapshot: homeState.afterSegmentationSnapshot
            )
        }
    }
}
