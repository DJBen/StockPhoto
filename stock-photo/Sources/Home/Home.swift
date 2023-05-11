import PhotosUI
import Segmentation
import StockPhotoFoundation
import SwiftUI
import UIKit

public struct HomeModel: Equatable {
    public var selectedPhotosPickerItem: PhotosPickerItem?
    public var transferredImage: Loadable<TransferredImage, SPError>
    public var uploadState: UploadFileState?
    public var projects: Loadable<[Project], SPError>
    public var images: [Int: Loadable<ProjectImages, SPError>]

    public init(
        selectedPhotosPickerItem: PhotosPickerItem? = nil,
        transferredImage: Loadable<TransferredImage, SPError> = .notLoaded,
        uploadState: UploadFileState? = nil,
        projects: Loadable<[Project], SPError> = .loading,
        images: [Int : Loadable<ProjectImages, SPError>] = [:]
    ) {
        self.selectedPhotosPickerItem = selectedPhotosPickerItem
        self.transferredImage = transferredImage
        self.uploadState = uploadState
        self.projects = projects
        self.images = images
    }
}

@dynamicMemberLookup
public struct HomeState: Equatable {
    public var account: Account?
    public var model: HomeModel
    public var segmentationModel: SegmentationModel
    public var selectedProjectID: Int?

    public init(
        account: Account?,
        model: HomeModel,
        segmentationModel: SegmentationModel,
        selectedProjectID: Int?
    ) {
        self.account = account
        self.model = model
        self.segmentationModel = segmentationModel
        self.selectedProjectID = selectedProjectID
    }

    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<HomeModel, Value>) -> Value {
        get {
            self.model[keyPath: keyPath]
        }
        set {
            self.model[keyPath: keyPath] = newValue
        }
    }
}

public enum HomeAction: Equatable, Sendable {
    // Import images
    case selectedPhotosPickerItem(PhotosPickerItem?)
    case didCompleteTransferImage(Loadable<TransferredImage, SPError>)
    case uploadImage(TransferredImage, account: Account)
    case updateUploadProgress(Result<UploadFileUpdate, SPError>, account: Account)
    case cancelUpload
    // Projects
    case fetchProjects(account: Account)
    case retryFetchingProjects(account: Account)
    case refreshProjects(account: Account)
    case fetchedProjects(Loadable<[Project], SPError>, account: Account)
    case selectProjectID(Int?)
    // Images
    case fetchImage(Project, account: Account)
    case fetchedImage(Loadable<ProjectImages, SPError>, project: Project, account: Account)

    case segmentation(SegmentationAction)
    case logout
}
