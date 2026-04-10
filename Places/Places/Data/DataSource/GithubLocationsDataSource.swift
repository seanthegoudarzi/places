import Foundation

protocol GithubRemoteLocationDataSource: Sendable {
    func fetchLocations() async throws -> [Location]
}

struct DefaultGithubLocationsDataSource: GithubRemoteLocationDataSource {
    private let urlString = "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLocations() async throws -> [Location] {
        guard let url = URL(string: urlString) else {
            throw LocationDataSourceError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LocationDataSourceError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(LocationsResponse.self, from: data)
        return decoded.locations
    }
}

enum LocationDataSourceError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error_invalid_url")
        case .invalidResponse:
            return String(localized: "error_invalid_response")
        }
    }
}

struct LocationsResponse: Codable, Sendable {
    let locations: [Location]
}
