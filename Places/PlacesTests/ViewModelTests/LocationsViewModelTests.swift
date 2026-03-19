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

    func testInitialState_hasNoLocations() {
        let vm = makeViewModel()
        viewModel = vm
        XCTAssertNil(vm.state.locations)
        XCTAssertFalse(vm.state.isLoading)
        XCTAssertNil(vm.state.errorMessage)
    }

    func testSend_fetchLocations_success_setsLocations() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([Location(name: "Amsterdam", lat: 52.35, long: 4.83)])
        let vm = makeViewModel(locationsRepository: mockRepo)
        viewModel = vm

        await vm.handle(.fetchLocations)

        XCTAssertFalse(vm.state.isLoading)
        XCTAssertEqual(vm.state.locations?.count, 1)
        XCTAssertEqual(vm.state.locations?[0].location.name, "Amsterdam")
        XCTAssertNil(vm.state.errorMessage)
    }

    func testSend_fetchLocations_failure_setsError() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .failure(MockError(message: "Offline"))
        let vm = makeViewModel(locationsRepository: mockRepo)
        viewModel = vm

        await vm.handle(.fetchLocations)

        XCTAssertFalse(vm.state.isLoading)
        XCTAssertEqual(vm.state.errorMessage, "Offline")
    }

    func testSend_fetchLocations_publishesNoEffect() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([])
        let vm = makeViewModel(locationsRepository: mockRepo)
        viewModel = vm
        var received: [LocationsListScreenEffect] = []

        vm.effectPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        await vm.handle(.fetchLocations)

        XCTAssertTrue(received.isEmpty)
    }

    func testSend_openInWikipedia_publishesOpenURLEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        let location = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        var received: [LocationsListScreenEffect] = []

        vm.effectPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        await vm.handle(.openInWikipedia(location))

        XCTAssertEqual(received.count, 1)
        if case .openURL(let url) = received[0] {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let lat = components?.queryItems?.first { $0.name == "latitude" }?.value
            let lon = components?.queryItems?.first { $0.name == "longitude" }?.value
            XCTAssertEqual(Double(lat ?? "") ?? 0, 52.3547498, accuracy: 0.0001)
            XCTAssertEqual(Double(lon ?? "") ?? 0, 4.8339215, accuracy: 0.0001)
        } else {
            XCTFail("Expected .openURL effect")
        }
    }

    func testSend_openInWikipedia_doesNotMutateState() async {
        let vm = makeViewModel()
        viewModel = vm
        let location = Location(name: "Amsterdam", lat: 52.35, long: 4.83)

        await vm.handle(.openInWikipedia(location))

        XCTAssertNil(vm.state.locations)
        XCTAssertFalse(vm.state.isLoading)
    }

    func testSend_openInWikipedia_consecutiveTaps_eachPublishEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        let location = Location(name: "Amsterdam", lat: 52.35, long: 4.83)
        var received: [LocationsListScreenEffect] = []

        vm.effectPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        await vm.handle(.openInWikipedia(location))
        await vm.handle(.openInWikipedia(location))

        XCTAssertEqual(received.count, 2)
    }

    // MARK: - wikipediaOpenFailed

    func testSend_wikipediaOpenFailed_setsAlertFlag() async {
        let vm = makeViewModel()
        viewModel = vm

        await vm.handle(.wikipediaOpenFailed)

        XCTAssertTrue(vm.state.showWikipediaNotInstalledAlert)
    }

    func testSend_wikipediaOpenFailed_publishesNoEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [LocationsListScreenEffect] = []

        vm.effectPublisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        await vm.handle(.wikipediaOpenFailed)

        XCTAssertTrue(received.isEmpty)
    }

    // MARK: - alertDismissed

    func testSend_alertDismissed_clearsAlertFlag() async {
        let vm = makeViewModel()
        viewModel = vm

        await vm.handle(.wikipediaOpenFailed)
        XCTAssertTrue(vm.state.showWikipediaNotInstalledAlert)

        await vm.handle(.wikipediaAlertDismissed)
        XCTAssertFalse(vm.state.showWikipediaNotInstalledAlert)
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
