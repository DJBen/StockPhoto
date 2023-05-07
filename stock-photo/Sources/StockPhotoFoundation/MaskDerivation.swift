
public struct MaskDerivation: Equatable, Decodable, Sendable {
    public let id: Int
    public let imageID: Int
    public let mask: AppliedMask

    private enum CodingKeys: String, CodingKey {
        case id
        case imageID = "image_id"
        case mask
    }
}

public struct AppliedMask: Equatable, Decodable, Sendable {
    public let maskID: Int
    public let imageID: Int
    public let pointSemantics: [PointSemantic]
    public let mask: Mask

    public init(
        maskID: Int,
        imageID: Int,
        pointSemantics: [PointSemantic],
        mask: Mask
    ) {
        self.maskID = maskID
        self.imageID = imageID
        self.pointSemantics = pointSemantics
        self.mask = mask
    }

    private enum CodingKeys: String, CodingKey {
        case maskID = "mask_id"
        case imageID = "image_id"
        case pointCoords = "point_coords"
        case pointLabels = "point_labels"
        case mask
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let pointCoords = try container.decodeIfPresent([Point].self, forKey: .pointCoords)
        let pointLabels = try container.decodeIfPresent([PointLabel].self, forKey: .pointLabels)
        let pointSemantics: [PointSemantic]
        if let pointCoords = pointCoords, let pointLabels = pointLabels {
            pointSemantics = zip(pointCoords, pointLabels).map {
                PointSemantic(point: $0, label: $1)
            }
        } else {
            pointSemantics = []
        }

        self.init(
            maskID: try container.decode(Int.self, forKey: .maskID),
            imageID: try container.decode(Int.self, forKey: .imageID),
            pointSemantics: pointSemantics,
            mask: try container.decode(Mask.self, forKey: .mask)
        )
    }
}
