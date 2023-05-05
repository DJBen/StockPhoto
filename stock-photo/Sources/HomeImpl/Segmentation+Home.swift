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
            guard let imageProject = imageProjects.value?.first(where: { $0.fileName == fileName }) else {
                return nil
            }
            guard let accessToken = homeState.accessToken else {
                return nil
            }
            guard let image = imageLoadable?.value else {
                return nil
            }
            return SegmentationState(
                model: homeState.segmentationModel,
                accessToken: accessToken,
                fileName: imageProject.fileName,
                image: image
            )
        }
    }
}
