import Foundation
@testable import Places

final class MockInMemoryLocationDataSource: TemporaryInMemoryLocationDataSource, @unchecked Sendable {
    var locations: [Location] = []

    func addLocation(_ location: Location) async {
        locations.append(location)
    }
}
