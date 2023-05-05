import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI
import UIKit

public struct HomeState: Equatable {
    public var accessToken: String?
    public var selectedPhotosPickerItem: PhotosPickerItem?
    public var transferredImage: Loadable<Image, SPError>
    public var imageProjects: Loadable<[ImageProject], SPError>
    public var images: [Int: Loadable<UIImage, SPError>]
    public var selectedImageProjectID: Int?
    public var segmentationModel: SegmentationModel

    public init(
        accessToken: String?,
        selectedPhotosPickerItem: PhotosPickerItem?,
        transferredImage: Loadable<Image, SPError>,
        imageProjects: Loadable<[ImageProject], SPError>,
        images: [Int: Loadable<UIImage, SPError>],
        selectedImageProjectID: Int?,
        segmentationModel: SegmentationModel
    ) {
        self.accessToken = accessToken
        self.selectedPhotosPickerItem = selectedPhotosPickerItem
        self.transferredImage = transferredImage
        self.imageProjects = imageProjects
        self.images = images
        self.selectedImageProjectID = selectedImageProjectID
        self.segmentationModel = segmentationModel
    }
}

public enum HomeAction: Equatable {
    case selectedPhotosPickerItem(PhotosPickerItem?)
    case didCompleteTransferImage(Loadable<Image, SPError>)
    case fetchImageProjects(accessToken: String)
    case fetchedImageProjects(Loadable<[ImageProject], SPError>, accessToken: String)
    case fetchImage(ImageProject, accessToken: String)
    case fetchedImage(Loadable<UIImage, SPError>, imageProject: ImageProject, accessToken: String)
    case selectImageProjectID(Int?)
    case segmentation(SegmentationAction)
    case logout
}
