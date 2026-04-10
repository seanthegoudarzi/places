import XCTest
import Combine
@testable import Places

@MainActor
final class LocationsViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: LocationsListScreenViewModel?

    override func setUp() {
        super.setUp()
        cancellables = []
        viewModel = nil
    }

    override func tearDown() {
        viewModel = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testHandle_delegatesToIntentHandler_updatingState() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([Location(name: "Amsterdam", lat: 52.35, long: 4.83)])
        let vm = makeViewModel(locationsRepository: mockRepo)
        viewModel = vm

        await vm.handle(.fetchLocations)

        XCTAssertNotNil(vm.state.locations, "State should be updated via intent handler")
    }

    func testHandle_delegatesToIntentHandler_publishingEffects() async {
        let vm = makeViewModel()
        viewModel = vm
        let location = Location(name: "Amsterdam", lat: 52.35, long: 4.83)
        var received: [LocationsListScreenEffect] = []

        vm.effectPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        await vm.handle(.openInWikipedia(location))

        XCTAssertEqual(received.count, 1, "Effects from intent handler should be published")
    }

    func testHandle_consecutiveIntents_eachPublishEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        let location = Location(name: "Amsterdam", lat: 52.35, long: 4.83)
        var received: [LocationsListScreenEffect] = []

        vm.effectPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        await vm.handle(.openInWikipedia(location))
        await vm.handle(.openInWikipedia(location))

        XCTAssertEqual(received.count, 2, "Each intent should produce its own effect")
    }

    // MARK: - Helpers

    private func makeViewModel(
        locationsRepository: LocationsRepository = MockLocationsRepository(),
        coordinateFormatter: CoordinateFormatter = MockCoordinateFormatter()
    ) -> LocationsListScreenViewModel {
        let intentHandler = LocationsScreenIntentHandler(
            locationsRepository: locationsRepository,
            coordinateFormatter: coordinateFormatter
        )
        return LocationsListScreenViewModel(intentHandler: intentHandler)
    }
}
