import Foundation

actor TemporaryInMemoryLocationDataSource {
    private(set) var locations: [Location] = []

    func addLocation(_ location: Location) {
        locations.append(location)
    }
}
