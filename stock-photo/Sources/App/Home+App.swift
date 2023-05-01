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
            segmentationResult: appState.segmentationResult,
            afterSegmentationSnapshot: appState.afterSegmentationSnapshot
        )
    }

    func apply(_ appState: inout StockPhoto.State) {
        appState.selectedPhotoPickerItem = selectedPhotosPickerItem
        appState.transferredImage = transferredImage
        appState.imageProjects = imageProjects
        appState.images = images
        appState.selectedImageProjectID = selectedImageProjectID
        appState.segmentationResult = segmentationResult
        appState.afterSegmentationSnapshot = afterSegmentationSnapshot
    }
}
