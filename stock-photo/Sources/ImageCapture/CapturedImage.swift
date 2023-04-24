import AVFoundation
import Foundation
import UIKit

public struct CapturedImage: Equatable, Identifiable {
    public var id: UUID
    public var image: UIImage
    public var depthData: AVDepthData?

    public init(id: UUID, image: UIImage, depthData: AVDepthData? = nil) {
        self.id = id
        self.image = image
        self.depthData = depthData
    }
}
