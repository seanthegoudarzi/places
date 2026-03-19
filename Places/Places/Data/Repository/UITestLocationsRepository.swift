import Foundation

enum UITestScenario: String {
    case loaded
    case empty
    case error
}

final class UITestLocationsRepository: LocationsRepository {
    private let scenario: UITestScenario
    private var customLocations: [Location] = []
    private let lock = NSLock()

    init(scenario: UITestScenario) {
        self.scenario = scenario
    }

    func fetchLocations() async throws -> [Location] {
        switch scenario {
        case .loaded:
            let base = [
                Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215),
                Location(name: "Mumbai", lat: 19.0759837, long: 72.8776559),
                Location(name: "Copenhagen", lat: 55.6760968, long: 12.5683372),
                Location(name: nil, lat: 40.4380638, long: -3.7495758)
            ]
            return lock.withLock { base + customLocations }

        case .empty:
            return lock.withLock { customLocations }

        case .error:
            throw NSError(
                domain: "UITest",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to connect to the server."]
            )
        }
    }

    func addLocation(_ location: Location) async {
        lock.withLock { customLocations.append(location) }
    }
}
