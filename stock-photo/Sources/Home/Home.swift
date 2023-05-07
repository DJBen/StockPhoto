import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI
import UIKit

public struct HomeState: Equatable {
    public var account: Account?
    public var selectedPhotosPickerItem: PhotosPickerItem?
    public var transferredImage: Loadable<Image, SPError>
    public var projects: Loadable<[Project], SPError>
    public var images: [Int: Loadable<ProjectImages, SPError>]
    public var selectedProjectID: Int?
    public var segmentationModel: SegmentationModel

    public init(
        account: Account?,
        selectedPhotosPickerItem: PhotosPickerItem?,
        transferredImage: Loadable<Image, SPError>,
        projects: Loadable<[Project], SPError>,
        images: [Int: Loadable<ProjectImages, SPError>],
        selectedProjectID: Int?,
        segmentationModel: SegmentationModel
    ) {
        self.account = account
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
    case fetchProjects(account: Account)
    case retryFetchingProjects(account: Account)
    case fetchedProjects(Loadable<[Project], SPError>, account: Account)
    case fetchImage(Project, account: Account)
    case fetchedImage(Loadable<ProjectImages, SPError>, project: Project, account: Account)
    case selectProjectID(Int?)
    case segmentation(SegmentationAction)
    case logout
}
