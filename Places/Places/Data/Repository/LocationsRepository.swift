import Foundation

protocol LocationsRepository: Sendable {
    func fetchLocations() async throws -> [Location]
    func addLocation(_ location: Location) async
}
