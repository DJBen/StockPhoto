import XCTest
import Home
import NetworkClient
import Nuke
import StockPhotoFoundation
import Segmentation
import ComposableArchitecture
@testable import HomeImpl

final class MockNetworkClient: NetworkClient {
    func authenticateGoogle(_ request: AuthenticateGoogleRequest) async throws -> AuthenticateGoogleResponse {
        fatalError()
    }
    
    func authenticateApple(_ request: AuthenticateAppleRequest) async throws -> AuthenticateAppleResponse {
        fatalError()
    }
    
    func listProjects(_ request: ListProjectsRequest) async throws -> ListProjectsResponse {
        fatalError()
    }
    
    func fetchImage(_ request: FetchImageRequest) async throws -> UIImage {
        return UIImage()
    }
    
    func uploadImage(_ request: UploadImageRequest) -> AsyncThrowingStream<UploadFileUpdate, Error> {
        fatalError()
    }
    
    func deleteImage(_ request: DeleteImageRequest) async throws -> DeleteImageResponse {
        fatalError()
    }
    
    func segment(_ request: SegmentRequest) async throws -> SegmentResponse {
        fatalError()
    }
    
    func confirmMask(_ request: ConfirmMaskRequest) async throws -> ConfirmMaskResponse {
        fatalError()
    }
}

final class MockSegmentationReducer: ReducerProtocol {
    typealias State = SegmentationState

    typealias Action = SegmentationAction

    var body: some ReducerProtocol<SegmentationState, SegmentationAction> {
        Reduce { state, action in .none }
    }
}

final class MockDataCache: DataCaching {
    func cachedData(for key: String) -> Data? {
        fatalError()
    }

    func containsData(for key: String) -> Bool {
        fatalError()
    }

    func storeData(_ data: Data, for key: String) {
        fatalError()
    }

    func removeData(for key: String) {
        fatalError()
    }

    func removeAll() {
        fatalError()
    }
}

@MainActor
final class HomeTests: XCTestCase {
    func testExample() async throws {
        let homeReducer = Home(
            networkClient: MockNetworkClient(),
            dataCache: MockDataCache(),
            segmentationReducerFactory: {
                MockSegmentationReducer()
            }
        )
        let store = TestStore(
            initialState: HomeState(
                account: nil,
                model: HomeModel(),
                segmentationModel: SegmentationModel(),
                selectedProjectID: nil
            ),
            reducer: homeReducer
        )

        let account = Account(accessToken: "123", userID: "123")

        await store.send(
            .fetchImage(
                Project(image: ImageDescriptor(id: 123), maskDerivation: nil),
                account: account
            )
        )
        await store.receive({ action in
            guard case let .fetchedImage(loadable, project: project, account: account) = action else {
                return false
            }
            // Add asserts
            return true
        }, timeout: .seconds(1.0)) { state in
            state.images = [
                123: .loaded(ProjectImages(image: UIImage(), maskedImage: nil))
            ]
        }
    }
}
