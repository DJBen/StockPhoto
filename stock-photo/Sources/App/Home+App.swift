import Home

extension HomeState {
    static func project(_ appState: StockPhoto.State) -> HomeState {
        HomeState(
            accessToken: appState.login.accessToken,
            selectedPhotosPickerItem: appState.selectedPhotoPickerItem,
            transferredImage: appState.transferredImage,
            imageProjects: appState.imageProjects,
            images: appState.images,
            selectedImageProjectID: appState.selectedImageProjectID,
            segmentationModel: appState.segmentationModel
        )
    }

    func apply(_ appState: inout StockPhoto.State) {
        appState.login.accessToken = accessToken
        appState.selectedPhotoPickerItem = selectedPhotosPickerItem
        appState.transferredImage = transferredImage
        appState.imageProjects = imageProjects
        appState.images = images
        appState.selectedImageProjectID = selectedImageProjectID
        appState.segmentationModel = segmentationModel
    }
}
