import XCTest
@testable import Places

@MainActor
final class CustomLocationIntentHandlerTests: XCTestCase {

    // MARK: - updateName

    func testUpdateName_emitsNewState_noEffect() async {
        let states = ValueCollector<CustomLocationScreenState>()
        let effects = ValueCollector<CustomLocationScreenEffect>()

        await makeHandler().handle(.updateName("Amsterdam"), state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 1)
        XCTAssertEqual(states.values[0].nameText, "Amsterdam")
        XCTAssertTrue(effects.isEmpty)
    }

    func testUpdateName_doesNotAffectValidation() async {
        var state = CustomLocationScreenState()
        state.latitudeText = "52.35"
        state.longitudeText = "4.83"
        state.isAddButtonEnabled = true
        let states = ValueCollector<CustomLocationScreenState>()

        await makeHandler().handle(.updateName("New Name"), state: state, context: makeContext(states: states))

        XCTAssertEqual(states.last?.nameText, "New Name")
        XCTAssertTrue(states.last?.isAddButtonEnabled ?? false, "updateName should not change isAddButtonEnabled")
    }

    // MARK: - updateLatitude

    func testUpdateLatitude_emitsUpdatedText_noEffect() async {
        let states = ValueCollector<CustomLocationScreenState>()
        let effects = ValueCollector<CustomLocationScreenEffect>()

        await makeHandler().handle(.updateLatitude("52.35"), state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 1)
        XCTAssertEqual(states.values[0].latitudeText, "52.35")
        XCTAssertTrue(effects.isEmpty)
    }

    func testUpdateLatitude_withValidBothFields_enablesButton() async {
        var state = CustomLocationScreenState()
        state.longitudeText = "4.83"
        let states = ValueCollector<CustomLocationScreenState>()

        await makeHandler().handle(.updateLatitude("52.35"), state: state, context: makeContext(states: states))

        XCTAssertTrue(states.last?.isAddButtonEnabled ?? false)
        XCTAssertNil(states.last?.validationError)
    }

    func testUpdateLatitude_withNonNumeric_disablesButtonAndSetsError() async {
        var state = CustomLocationScreenState()
        state.longitudeText = "4.83"
        let states = ValueCollector<CustomLocationScreenState>()

        await makeHandler().handle(.updateLatitude("abc"), state: state, context: makeContext(states: states))

        XCTAssertFalse(states.last?.isAddButtonEnabled ?? true)
        XCTAssertNotNil(states.last?.validationError)
    }

    func testUpdateLatitude_outOfRange_disablesButtonAndSetsError() async {
        var state = CustomLocationScreenState()
        state.longitudeText = "4.83"
        let states = ValueCollector<CustomLocationScreenState>()

        await makeHandler().handle(.updateLatitude("91"), state: state, context: makeContext(states: states))

        XCTAssertFalse(states.last?.isAddButtonEnabled ?? true)
        XCTAssertNotNil(states.last?.validationError)
    }

    // MARK: - updateLongitude

    func testUpdateLongitude_emitsUpdatedText_noEffect() async {
        let states = ValueCollector<CustomLocationScreenState>()
        let effects = ValueCollector<CustomLocationScreenEffect>()

        await makeHandler().handle(.updateLongitude("4.83"), state: .init(), context: makeContext(states: states, effects: effects))

        XCTAssertEqual(states.count, 1)
        XCTAssertEqual(states.values[0].longitudeText, "4.83")
        XCTAssertTrue(effects.isEmpty)
    }

    func testUpdateLongitude_withValidBothFields_enablesButton() async {
        var state = CustomLocationScreenState()
        state.latitudeText = "52.35"
        let states = ValueCollector<CustomLocationScreenState>()

        await makeHandler().handle(.updateLongitude("4.83"), state: state, context: makeContext(states: states))

        XCTAssertTrue(states.last?.isAddButtonEnabled ?? false)
        XCTAssertNil(states.last?.validationError)
    }

    func testUpdateLongitude_outOfRange_disablesButtonAndSetsError() async {
        var state = CustomLocationScreenState()
        state.latitudeText = "52.35"
        let states = ValueCollector<CustomLocationScreenState>()

        await makeHandler().handle(.updateLongitude("181"), state: state, context: makeContext(states: states))

        XCTAssertFalse(states.last?.isAddButtonEnabled ?? true)
        XCTAssertNotNil(states.last?.validationError)
    }

    // MARK: - Boundary values

    func testBoundaryValues_latNeg90_lon180_enablesButton() async {
        var state = CustomLocationScreenState()
        var statesA = ValueCollector<CustomLocationScreenState>()
        await makeHandler().handle(.updateLatitude("-90"), state: state, context: makeContext(states: statesA))
        state = statesA.last ?? state
        statesA = ValueCollector()
        await makeHandler().handle(.updateLongitude("180"), state: state, context: makeContext(states: statesA))
        state = statesA.last ?? state
        XCTAssertTrue(state.isAddButtonEnabled)
    }

    // MARK: - addLocation

    func testAddLocation_withValidCoordsAndName_emitsDidAddEffect_noState() async {
        var state = CustomLocationScreenState()
        state.nameText = "My Place"
        state.latitudeText = "52.35"
        state.longitudeText = "4.83"
        state.isAddButtonEnabled = true
        let states = ValueCollector<CustomLocationScreenState>()
        let effects = ValueCollector<CustomLocationScreenEffect>()

        await makeHandler().handle(.addLocation, state: state, context: makeContext(states: states, effects: effects))

        XCTAssertTrue(states.isEmpty)
        XCTAssertEqual(effects.count, 1)
        if case .navigateToRoot(let location) = effects.values[0] {
            XCTAssertEqual(location.name, "My Place")
            XCTAssertEqual(location.lat, 52.35, accuracy: 0.001)
            XCTAssertEqual(location.long, 4.83, accuracy: 0.001)
        } else {
            XCTFail("Expected .didAdd effect")
        }
    }

    func testAddLocation_withWhitespaceOnlyName_producesNilLocationName() async {
        var state = CustomLocationScreenState()
        state.nameText = "   "
        state.latitudeText = "52.35"
        state.longitudeText = "4.83"
        state.isAddButtonEnabled = true
        let effects = ValueCollector<CustomLocationScreenEffect>()

        await makeHandler().handle(.addLocation, state: state, context: makeContext(effects: effects))

        if case .navigateToRoot(let location) = effects.values[0] {
            XCTAssertNil(location.name, "Whitespace-only name should produce nil")
        } else {
            XCTFail("Expected .didAdd effect")
        }
    }

    func testAddLocation_whenButtonDisabled_emitsNothing() async {
        var state = CustomLocationScreenState()
        state.latitudeText = "52.35"
        state.longitudeText = "4.83"
        state.isAddButtonEnabled = false
        let states = ValueCollector<CustomLocationScreenState>()
        let effects = ValueCollector<CustomLocationScreenEffect>()

        await makeHandler().handle(.addLocation, state: state, context: makeContext(states: states, effects: effects))

        XCTAssertTrue(states.isEmpty)
        XCTAssertTrue(effects.isEmpty)
    }

    func testHandlerIsStateless_independentCallsDoNotShareState() async {
        let states1 = ValueCollector<CustomLocationScreenState>()
        let states2 = ValueCollector<CustomLocationScreenState>()
        await makeHandler().handle(.updateLatitude("10"), state: .init(), context: makeContext(states: states1))
        await makeHandler().handle(.updateLatitude("20"), state: .init(), context: makeContext(states: states2))
        XCTAssertEqual(states1.last?.latitudeText, "10")
        XCTAssertEqual(states2.last?.latitudeText, "20")
    }

    // MARK: - Helpers

    private func makeHandler() -> CustomLocationScreenIntentHandler {
        CustomLocationScreenIntentHandler(
            locationsRepository: MockLocationsRepository(),
            coordinateFormatter: MockCoordinateFormatter()
        )
    }

    private func makeContext(
        states: ValueCollector<CustomLocationScreenState> = ValueCollector(),
        effects: ValueCollector<CustomLocationScreenEffect> = ValueCollector()
    ) -> IntentContext<CustomLocationScreenState, CustomLocationScreenEffect> {
        IntentContext(updateState: states.collect, effect: effects.collect)
    }
}
