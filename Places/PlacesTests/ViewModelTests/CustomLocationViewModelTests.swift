import XCTest
import Combine
@testable import Places

@MainActor
final class CustomLocationViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: CustomLocationScreenViewModel?

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

    func testInitialState_isEmpty() {
        let vm = makeViewModel()
        viewModel = vm
        XCTAssertEqual(vm.state.nameText, "")
        XCTAssertEqual(vm.state.latitudeText, "")
        XCTAssertEqual(vm.state.longitudeText, "")
        XCTAssertFalse(vm.state.isAddButtonEnabled)
    }

    func testSend_updateName_updatesState_publishesNoEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.updateName("Amsterdam"))

        XCTAssertEqual(vm.state.nameText, "Amsterdam")
        XCTAssertTrue(received.isEmpty)
    }

    func testSend_updateLatitude_updatesState_publishesNoEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.updateLatitude("52.35"))

        XCTAssertEqual(vm.state.latitudeText, "52.35")
        XCTAssertTrue(received.isEmpty)
    }

    func testSend_updateLongitude_updatesState_publishesNoEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.updateLongitude("4.83"))

        XCTAssertEqual(vm.state.longitudeText, "4.83")
        XCTAssertTrue(received.isEmpty)
    }

    func testSend_addLocation_withValidCoordsAndName_publishesDidAddEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.updateLatitude("52.35"))
        await vm.handle(.updateLongitude("4.83"))
        await vm.handle(.updateName("My Place"))
        await vm.handle(.addLocation)

        XCTAssertEqual(received.count, 1)
        if case .navigateToRoot(let location) = received[0] {
            XCTAssertEqual(location.name, "My Place")
            XCTAssertEqual(location.lat, 52.35, accuracy: 0.001)
            XCTAssertEqual(location.long, 4.83, accuracy: 0.001)
        } else {
            XCTFail("Expected .didAdd effect")
        }
    }

    func testSend_addLocation_withInvalidCoords_publishesNoEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.addLocation)

        XCTAssertTrue(received.isEmpty)
    }

    func testSend_addLocation_consecutiveTaps_eachPublishesEffect() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.updateLatitude("52.35"))
        await vm.handle(.updateLongitude("4.83"))
        await vm.handle(.addLocation)
        await vm.handle(.addLocation)

        XCTAssertEqual(received.count, 2)
    }

    // MARK: - Helpers

    private func makeViewModel() -> CustomLocationScreenViewModel {
        let intentHandler = CustomLocationScreenIntentHandler(
            locationsRepository: MockLocationsRepository(),
            coordinateFormatter: MockCoordinateFormatter()
        )
        return CustomLocationScreenViewModel(
            intentHandler: intentHandler,
            initialState: intentHandler.makeInitialState()
        )
    }
}
