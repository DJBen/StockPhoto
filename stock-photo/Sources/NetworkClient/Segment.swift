import Segmentation

public struct SegmentRequest: Equatable, Encodable {
    public let accessToken: String
    public let fileName: String
    public let pointSemantic: PointSemantic

    public init(
        accessToken: String,
        fileName: String,
        pointSemantic: PointSemantic
    ) {
        self.accessToken = accessToken
        self.fileName = fileName
        self.pointSemantic = pointSemantic
    }

    private enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case pointCoords = "point_coords"
        case pointLabels = "point_labels"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
        try container.encode([pointSemantic.point], forKey: .pointCoords)
        try container.encode([pointSemantic.label.rawValue], forKey: .pointLabels)
    }
}

public struct SegmentResponse: Equatable, Decodable {
    public let masks: [Mask]
}
