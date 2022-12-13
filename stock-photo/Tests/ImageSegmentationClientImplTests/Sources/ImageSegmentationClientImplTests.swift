//
//  ImageSegmentationClientImplTests.swift
//  
//
//  Created by Ben Lu on 12/11/22.
//

import XCTest
import ImageSegmentationClient
@testable import ImageSegmentationClientImpl
import SnapshotTesting

final class ImageSegmentationClientImplTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func test_imageSegmentation() async throws {
        let result = try await ImageSegmentationClient.liveValue.segment(
            ImageSegmentationRequest(
                image: UIImage(named: "example", in: .module, with: nil)!,
                requestedContents: .rawMask
            )
        )
        assertSnapshot(matching: UIImage(cgImage: CGImage.create(pixelBuffer: result.rawMask!)!), as: .image(precision: 0.98, perceptualPrecision: 0.98))
    }

    func test_imageSegmentation_performance_rawMask() throws {
        measure {
            let exp = expectation(description: "Finished")

            Task {
                _ = try await ImageSegmentationClient.liveValue.segment(
                    ImageSegmentationRequest(
                        image: UIImage(named: "example", in: .module, with: nil)!,
                        requestedContents: .rawMask
                    )
                )
                exp.fulfill()
            }

            wait(for: [exp], timeout: 10.0)
        }
    }

    func test_imageSegmentation_performance_finalImage() throws {
        measure {
            let exp = expectation(description: "Finished")

            Task {
                _ = try await ImageSegmentationClient.liveValue.segment(
                    ImageSegmentationRequest(
                        image: UIImage(named: "example", in: .module, with: nil)!,
                        requestedContents: .finalImage
                    )
                )
                exp.fulfill()
            }

            wait(for: [exp], timeout: 10.0)
        }
    }
}

