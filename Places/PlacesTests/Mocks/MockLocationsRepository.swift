import Foundation
@testable import Places

final class MockLocationsRepository: LocationsRepository, @unchecked Sendable {
    var result: Result<[Location], Error> = .success([])
    var fetchCallCount = 0
    var addedLocations: [Location] = []

    func fetchLocations() async throws -> [Location] {
        fetchCallCount += 1
        return try result.get()
    }

    func addLocation(_ location: Location) async {
        addedLocations.append(location)
    }
}

struct MockError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
