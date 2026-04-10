import XCTest
@testable import Places

@MainActor
final class DefaultLocationsRepositoryTests: XCTestCase {
    private var mockRemote: MockRemoteLocationDataSource!
    private var mockInMemory: MockInMemoryLocationDataSource!

    override func setUp() {
        super.setUp()
        mockRemote = MockRemoteLocationDataSource()
        mockInMemory = MockInMemoryLocationDataSource()
    }

    override func tearDown() {
        mockRemote = nil
        mockInMemory = nil
        super.tearDown()
    }

    func testFetchLocations_combinesRemoteAndLocalResults() async throws {
        mockRemote.result = .success([Location(name: "Remote", lat: 1.0, long: 2.0)])
        mockInMemory.locations = [Location(name: "Local", lat: 3.0, long: 4.0)]

        let result = try await makeSUT().fetchLocations()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Reemote")
        XCTAssertEqual(result[1].name, "Local")
    }

    func testFetchLocations_returnsOnlyRemoteWhenLocalIsEmpty() async throws {
        mockRemote.result = .success([Location(name: "Remote", lat: 1.0, long: 2.0)])

        let result = try await makeSUT().fetchLocations()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Remote")
    }

    func testFetchLocations_returnsOnlyLocalWhenRemoteIsEmpty() async throws {
        mockRemote.result = .success([])
        mockInMemory.locations = [Location(name: "Local", lat: 3.0, long: 4.0)]

        let result = try await makeSUT().fetchLocations()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Local")
    }

    func testFetchLocations_throwsWhenRemoteFails() async {
        mockRemote.result = .failure(MockError(message: "network error"))

        do {
            _ = try await makeSUT().fetchLocations()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, "network error")
        }
    }

    func testAddLocation_delegatesToInMemoryDataSource() async {
        let location = Location(name: "New", lat: 5.0, long: 6.0)

        await makeSUT().addLocation(location)

        XCTAssertEqual(mockInMemory.locations.count, 1)
        XCTAssertEqual(mockInMemory.locations[0].name, "New")
    }

    func testFetchLocations_callsRemoteDataSource() async throws {
        mockRemote.result = .success([])

        _ = try await makeSUT().fetchLocations()

        XCTAssertEqual(mockRemote.fetchCallCount, 1)
    }

    // MARK: - Helpers

    private func makeSUT() -> DefaultLocationsRepository {
        DefaultLocationsRepository(
            githubDataSource: mockRemote,
            inMemoryDataSource: mockInMemory
        )
    }
}
