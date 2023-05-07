import Foundation
import StockPhotoFoundation

public struct ListProjectsRequest: Equatable, Encodable {
    public let accessToken: String

    public init(
        accessToken: String
    ) {
        self.accessToken = accessToken
    }
}

public struct ListProjectsResponse: Equatable, Decodable {
    public let projects: [Project]

    public init(projects: [Project]) {
        self.projects = projects
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.projects = try container.decode([Project].self, forKey: .projects)
    }

    private enum CodingKeys: String, CodingKey {
        case projects
    }
}
