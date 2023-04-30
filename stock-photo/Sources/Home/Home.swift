import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI

public struct HomeState: Equatable {
    public var accessToken: String?
    public var selectedPhotosPickerItem: PhotosPickerItem?
    public var transferredImage: Loadable<Image, SPError>
    public var imageProjects: Loadable<[ImageProject], SPError>
    public var images: [String: Loadable<UIImage, SPError>]
    public var selectedImageProjectID: String?
    public var segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>]

    public init(
        accessToken: String?,
        selectedPhotosPickerItem: PhotosPickerItem?,
        transferredImage: Loadable<Image, SPError>,
        imageProjects: Loadable<[ImageProject], SPError>,
        images: [String: Loadable<UIImage, SPError>],
        selectedImageProjectID: String?,
        segmentationResult: [SegmentationIdentifier: Loadable<[Mask], SPError>]
    ) {
        self.accessToken = accessToken
        self.selectedPhotosPickerItem = selectedPhotosPickerItem
        self.transferredImage = transferredImage
        self.imageProjects = imageProjects
        self.images = images
        self.selectedImageProjectID = selectedImageProjectID
        self.segmentationResult = segmentationResult
    }
}

public enum HomeAction: Equatable {
    case selectedPhotosPickerItem(PhotosPickerItem?)
    case didCompleteTransferImage(Loadable<Image, SPError>)
    case fetchImageProjects(accessToken: String)
    case fetchedImageProjects(Loadable<[ImageProject], SPError>, accessToken: String)
    case fetchImage(ImageProject, accessToken: String)
    case fetchedImage(Loadable<UIImage, SPError>, imageProject: ImageProject, accessToken: String)
    case selectImageProjectID(String?)
    case segmentation(SegmentationAction)
}
