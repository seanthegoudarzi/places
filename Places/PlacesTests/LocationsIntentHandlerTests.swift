import XCTest
@testable import Places

@MainActor
final class LocationsIntentHandlerTests: XCTestCase {

    func testFetchLocations_emitsLoadingThenLoaded() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([
            Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215),
            Location(name: "Mumbai", lat: 19.0823998, long: 72.8111468)
        ])
        let handler = makeHandler(locationsRepository: mockRepo)
        let states = ValueCollector<LocationsListScreenState>()
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.fetchLocations, state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 2)
        XCTAssertTrue(states.values[0].isLoading)
        XCTAssertNil(states.values[0].locations)

        XCTAssertFalse(states.values[1].isLoading)
        XCTAssertEqual(states.values[1].locations?.count, 2)
        XCTAssertEqual(states.values[1].locations?[0].location.name, "Amsterdam")
    }

    func testFetchLocations_emitsLoadingThenError() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .failure(MockError(message: "Network error"))
        let handler = makeHandler(locationsRepository: mockRepo)
        let states = ValueCollector<LocationsListScreenState>()
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.fetchLocations, state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 2)
        XCTAssertTrue(states.values[0].isLoading)
        XCTAssertFalse(states.values[1].isLoading)
        XCTAssertEqual(states.values[1].errorMessage, "Network error")
    }

    func testFetchLocations_callsRepositoryExactlyOnce() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([])
        let handler = makeHandler(locationsRepository: mockRepo)

        await handler.handle(.fetchLocations, state: .init(), context: makeContext())

        XCTAssertEqual(mockRepo.fetchCallCount, 1)
    }

    func testFetchLocations_preservesExistingLocationsWhileLoading() async {
        let existing = [LocationDisplayItem(
            location: Location(name: "Amsterdam", lat: 52.35, long: 4.83),
            coordinatesText: "52.3500, 4.8300",
            accessibilityLabel: "Amsterdam, 52.3500, 4.8300"
        )]
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([])
        let handler = makeHandler(locationsRepository: mockRepo)
        let initial = LocationsListScreenState(locations: existing)
        let states = ValueCollector<LocationsListScreenState>()

        await handler.handle(.fetchLocations, state: initial, context: makeContext(states: states))

        XCTAssertTrue(states.values[0].isLoading)
        XCTAssertEqual(states.values[0].locations, existing)
    }

    func testFetchLocations_emitsNoEffects() async {
        let mockRepo = MockLocationsRepository()
        mockRepo.result = .success([])
        let handler = makeHandler(locationsRepository: mockRepo)
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.fetchLocations, state: .init(), context: makeContext(effects: effects))

        XCTAssertTrue(effects.isEmpty)
    }

    func testOpenInWikipedia_emitsOpenURLEffect() async {
        let handler = makeHandler()
        let location = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let states = ValueCollector<LocationsListScreenState>()
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.openInWikipedia(location), state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(effects.count, 1)
        if case .openURL(let url) = effects.values[0] {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let lat = components?.queryItems?.first { $0.name == "latitude" }?.value
            let lon = components?.queryItems?.first { $0.name == "longitude" }?.value
            XCTAssertEqual(Double(lat ?? "") ?? 0, 52.3547498, accuracy: 0.0001)
            XCTAssertEqual(Double(lon ?? "") ?? 0, 4.8339215, accuracy: 0.0001)
        } else {
            XCTFail("Expected .openURL effect")
        }
    }

    func testOpenInWikipedia_emitsNoStateChanges() async {
        let handler = makeHandler()
        let location = Location(name: "Amsterdam", lat: 52.35, long: 4.83)
        let states = ValueCollector<LocationsListScreenState>()

        await handler.handle(.openInWikipedia(location), state: .init(), context: makeContext(states: states))

        XCTAssertTrue(states.isEmpty)
    }

    // MARK: - wikipediaOpenFailed

    func testWikipediaOpenFailed_setsAlertFlag() async {
        let handler = makeHandler()
        let states = ValueCollector<LocationsListScreenState>()
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.wikipediaOpenFailed, state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 1)
        XCTAssertTrue(states.values[0].showWikipediaNotInstalledAlert)
        XCTAssertTrue(effects.isEmpty)
    }

    func testWikipediaOpenFailed_preservesExistingState() async {
        let handler = makeHandler()
        let existing = LocationsListScreenState(
            locations: [LocationDisplayItem(
                location: Location(name: "Amsterdam", lat: 52.35, long: 4.83),
                coordinatesText: "52.3500, 4.8300",
                accessibilityLabel: "Amsterdam, 52.3500, 4.8300"
            )]
        )
        let states = ValueCollector<LocationsListScreenState>()

        await handler.handle(.wikipediaOpenFailed, state: existing, context: makeContext(states: states))

        XCTAssertEqual(states.count, 1)
        XCTAssertTrue(states.values[0].showWikipediaNotInstalledAlert)
        XCTAssertEqual(states.values[0].locations?.count, 1)
    }

    // MARK: - alertDismissed

    func testAlertDismissed_clearsAlertFlag() async {
        let handler = makeHandler()
        let initial = LocationsListScreenState(showWikipediaNotInstalledAlert: true)
        let states = ValueCollector<LocationsListScreenState>()
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.wikipediaAlertDismissed, state: initial, context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 1)
        XCTAssertFalse(states.values[0].showWikipediaNotInstalledAlert)
        XCTAssertTrue(effects.isEmpty)
    }

    // MARK: - addLocationTapped

    func testAddLocationTapped_emitsNavigateEffect_noStateChange() async {
        let handler = makeHandler()
        let states = ValueCollector<LocationsListScreenState>()
        let effects = ValueCollector<LocationsListScreenEffect>()

        await handler.handle(.addLocationTapped, state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertTrue(states.isEmpty)
        XCTAssertEqual(effects.count, 1)
        if case .navigateToAddLocationPage = effects.values[0] {
            // Success
        } else {
            XCTFail("Expected .navigateToAddLocationPage effect")
        }
    }

    // MARK: - Helpers

    private func makeHandler(
        locationsRepository: LocationsRepository = MockLocationsRepository(),
        coordinateFormatter: CoordinateFormatter = MockCoordinateFormatter()
    ) -> LocationsScreenIntentHandler {
        LocationsScreenIntentHandler(
            locationsRepository: locationsRepository,
            coordinateFormatter: coordinateFormatter
        )
    }

    private func makeContext(
        states: ValueCollector<LocationsListScreenState> = ValueCollector(),
        effects: ValueCollector<LocationsListScreenEffect> = ValueCollector()
    ) -> IntentContext<LocationsListScreenState, LocationsListScreenEffect> {
        IntentContext(updateState: states.collect, effect: effects.collect)
    }
}
