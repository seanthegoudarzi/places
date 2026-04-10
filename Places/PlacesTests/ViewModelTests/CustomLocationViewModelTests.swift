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

    func testHandle_delegatesToIntentHandler_updatingState() async {
        let vm = makeViewModel()
        viewModel = vm

        await vm.handle(.updateName("My Place"))

        XCTAssertEqual(vm.state.nameText, "My Place", "State should be updated via intent handler")
    }

    func testHandle_delegatesToIntentHandler_publishingEffects() async {
        let vm = makeViewModel()
        viewModel = vm
        var received: [CustomLocationScreenEffect] = []
        vm.effectPublisher.sink { received.append($0) }.store(in: &cancellables)

        await vm.handle(.updateLatitude("52.35"))
        await vm.handle(.updateLongitude("4.83"))
        await vm.handle(.addLocation)

        XCTAssertEqual(received.count, 1, "Effects from intent handler should be published")
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
