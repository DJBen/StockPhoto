import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI
import UIKit

public struct HomeState: Equatable {
    public var accessToken: String?
    public var selectedPhotosPickerItem: PhotosPickerItem?
    public var transferredImage: Loadable<Image, SPError>
    public var projects: Loadable<[Project], SPError>
    public var images: [Int: Loadable<ProjectImages, SPError>]
    public var selectedProjectID: Int?
    public var segmentationModel: SegmentationModel

    public init(
        accessToken: String?,
        selectedPhotosPickerItem: PhotosPickerItem?,
        transferredImage: Loadable<Image, SPError>,
        projects: Loadable<[Project], SPError>,
        images: [Int: Loadable<ProjectImages, SPError>],
        selectedProjectID: Int?,
        segmentationModel: SegmentationModel
    ) {
        self.accessToken = accessToken
        self.selectedPhotosPickerItem = selectedPhotosPickerItem
        self.transferredImage = transferredImage
        self.projects = projects
        self.images = images
        self.selectedProjectID = selectedProjectID
        self.segmentationModel = segmentationModel
    }
}

public enum HomeAction: Equatable {
    case selectedPhotosPickerItem(PhotosPickerItem?)
    case didCompleteTransferImage(Loadable<Image, SPError>)
    case fetchProjects(accessToken: String)
    case fetchedProjects(Loadable<[Project], SPError>, accessToken: String)
    case fetchImage(Project, accessToken: String)
    case fetchedImage(Loadable<ProjectImages, SPError>, project: Project, accessToken: String)
    case selectProjectID(Int?)
    case segmentation(SegmentationAction)
    case logout
}
