import Foundation

protocol TemporaryInMemoryLocationDataSource: Sendable {
    var locations: [Location] { get async }
    func addLocation(_ location: Location) async
}

actor DefaultTemporaryInMemoryLocationDataSource: TemporaryInMemoryLocationDataSource {
    private(set) var locations: [Location] = []

    func addLocation(_ location: Location) {
        locations.append(location)
    }
}
