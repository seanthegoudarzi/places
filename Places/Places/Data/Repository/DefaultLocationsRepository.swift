import Foundation

struct DefaultLocationsRepository: LocationsRepository {
    private let githubDataSource: GithubLocationsDataSource
    private let inMemoryDataSource: TemporaryInMemoryLocationDataSource

    init(
        githubDataSource: GithubLocationsDataSource,
        inMemoryDataSource: TemporaryInMemoryLocationDataSource
    ) {
        self.githubDataSource = githubDataSource
        self.inMemoryDataSource = inMemoryDataSource
    }

    func fetchLocations() async throws -> [Location] {
        async let remote = githubDataSource.fetchLocations()
        async let local = inMemoryDataSource.locations
        let (remoteResult, localResult) = try await (remote, local)
        return remoteResult + localResult
    }

    func addLocation(_ location: Location) async {
        await inMemoryDataSource.addLocation(location)
    }
}
