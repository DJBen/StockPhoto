import Home

extension HomeState {
    static func project(_ appState: StockPhoto.State) -> HomeState {
        HomeState(
            accessToken: appState.login.accessToken,
            selectedPhotosPickerItem: appState.selectedPhotoPickerItem,
            transferredImage: appState.transferredImage,
            projects: appState.projects,
            images: appState.images,
            selectedProjectID: {
                for destination in appState.destinations {
                    switch destination {
                    case .selectedProject(let projectID):
                        return projectID
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
        appState.projects = projects
        appState.images = images
        appState.segmentationModel = segmentationModel
    }
}
