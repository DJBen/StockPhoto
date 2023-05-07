import Home
import Segmentation
import StockPhotoFoundation
import UIKit

extension SegmentationState {
    static func projectToHomeState(
        imageID: Int,
        projectImagesLoadable: Loadable<ProjectImages, SPError>?,
        projects: Loadable<[Project], SPError>
    ) -> (_ homeState: HomeState) -> SegmentationState? {
        { homeState in
            guard let project = projects.value?.first(where: { $0.id == imageID }) else {
                return nil
            }
            guard let image = projectImagesLoadable?.value else {
                return nil
            }
            return SegmentationState(
                model: homeState.segmentationModel,
                account: homeState.account,
                project: project,
                projectImages: image
            )
        }
    }
}
