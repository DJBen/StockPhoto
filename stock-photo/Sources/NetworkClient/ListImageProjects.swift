import Foundation
import Home

public struct ListImageProjectsRequest: Equatable, Encodable {
    public let accessToken: String

    public init(
        accessToken: String
    ) {
        self.accessToken = accessToken
    }
}

public struct ListImageProjectsResponse: Equatable, Decodable {
    public let imageProjects: [ImageProject]

    public init(imageProjects: [ImageProject]) {
        self.imageProjects = imageProjects
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.imageProjects = try container.decode([ImageProject].self, forKey: .imageProjects)
    }

    private enum CodingKeys: String, CodingKey {
        case imageProjects = "image_projects"
    }
}
