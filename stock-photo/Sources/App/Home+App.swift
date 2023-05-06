import Home

extension HomeState {
    static func project(_ appState: StockPhoto.State) -> HomeState {
        HomeState(
            accessToken: appState.login.accessToken,
            selectedPhotosPickerItem: appState.selectedPhotoPickerItem,
            transferredImage: appState.transferredImage,
            imageProjects: appState.imageProjects,
            images: appState.images,
            selectedImageProjectID: {
                for destination in appState.destinations {
                    switch destination {
                    case .selectedImageProject(let imageProjectID):
                        return imageProjectID
                    default:
                        break
                    }
                }
                return nil
            }(),
            segmentationModel: appState.segmentationModel
        )
    }

    func apply(_ appState: inout StockPhoto.State) {
        appState.selectedPhotoPickerItem = selectedPhotosPickerItem
        appState.transferredImage = transferredImage
        appState.imageProjects = imageProjects
        appState.images = images
        appState.segmentationModel = segmentationModel
    }
}
