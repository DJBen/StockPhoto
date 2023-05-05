import Segmentation

public struct SegmentRequest: Equatable, Encodable {
    public let accessToken: String
    public let imageID: Int
    public let pointSemantics: [PointSemantic]

    public init(
        accessToken: String,
        imageID: Int,
        pointSemantics: [PointSemantic]
    ) {
        self.accessToken = accessToken
        self.imageID = imageID
        self.pointSemantics = pointSemantics
    }

    private enum CodingKeys: String, CodingKey {
        case imageID = "image_id"
        case pointCoords = "point_coords"
        case pointLabels = "point_labels"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageID, forKey: .imageID)
        try container.encode(pointSemantics.map(\.point), forKey: .pointCoords)
        try container.encode(pointSemantics.map(\.label.rawValue), forKey: .pointLabels)
    }
}

public struct SegmentResponse: Equatable, Decodable {
    public let masks: [Mask]
    public let scores: [Float]
}
