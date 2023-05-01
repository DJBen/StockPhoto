import Segmentation

public struct SegmentRequest: Equatable, Encodable {
    public let accessToken: String
    public let fileName: String
    public let pointSemantics: [PointSemantic]

    public init(
        accessToken: String,
        fileName: String,
        pointSemantics: [PointSemantic]
    ) {
        self.accessToken = accessToken
        self.fileName = fileName
        self.pointSemantics = pointSemantics
    }

    private enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case pointCoords = "point_coords"
        case pointLabels = "point_labels"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(pointSemantics.map(\.point), forKey: .pointCoords)
        try container.encode(pointSemantics.map(\.label.rawValue), forKey: .pointLabels)
    }
}

public struct SegmentResponse: Equatable, Decodable {
    public let masks: [Mask]
}
