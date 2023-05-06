import Home
import Segmentation
import StockPhotoFoundation
import UIKit

extension SegmentationState {
    static func projectToHomeState(
        imageID: Int,
        imageLoadable: Loadable<UIImage, SPError>?,
        imageProjects: Loadable<[ImageProject], SPError>
    ) -> (_ homeState: HomeState) -> SegmentationState? {
        { homeState in
            guard let imageProject = imageProjects.value?.first(where: { $0.id == imageID }) else {
                return nil
            }
            guard let image = imageLoadable?.value else {
                return nil
            }
            return SegmentationState(
                model: homeState.segmentationModel,
                accessToken: homeState.accessToken,
                imageProject: imageProject,
                image: image
            )
        }
    }
}
