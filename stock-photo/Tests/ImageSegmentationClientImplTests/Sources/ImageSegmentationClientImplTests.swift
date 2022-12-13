//
//  ImageSegmentationClientImplTests.swift
//  
//
//  Created by Ben Lu on 12/11/22.
//

import XCTest
import ImageSegmentationClient
@testable import ImageSegmentationClientImpl

final class ImageSegmentationClientImplTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_imageSegmentation() async throws {
        let result = try await ImageSegmentationClient.liveValue.segment(
            ImageSegmentationRequest(image: UIImage(named: "example", in: .module, with: nil)!)
        )
        print(result)
    }
}

