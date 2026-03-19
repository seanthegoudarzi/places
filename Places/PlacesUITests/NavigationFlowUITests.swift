import XCTest

final class NavigationFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func launch(scenario: String) -> LocationsListPage {
        app.launchEnvironment["UI_TEST_SCENARIO"] = scenario
        app.launch()
        return LocationsListPage(app: app)
    }

    // MARK: - Forward Navigation

    @MainActor
    func testTapAdd_navigatesToCustomLocationScreen() throws {
        let list = launch(scenario: "loaded").waitForList()
        let form = list.tapAdd()

        XCTAssertTrue(form.navigationBar.exists)
        XCTAssertTrue(form.nameField.exists)
        XCTAssertTrue(form.latitudeField.exists)
        XCTAssertTrue(form.longitudeField.exists)
        XCTAssertTrue(form.submitButton.exists)
    }

    // MARK: - Back Navigation

    @MainActor
    func testBackButton_returnsToLocationsList() throws {
        let list = launch(scenario: "loaded").waitForList()
        let form = list.tapAdd()
        let returnedList = form.tapBack()

        XCTAssertTrue(returnedList.navigationBar.waitForExistence(timeout: 5))
        XCTAssertTrue(returnedList.list.exists)
    }

    // MARK: - Add Location → Navigate Back → Verify

    @MainActor
    func testAddNamedLocation_navigatesBackAndShowsIt() throws {
        let list = launch(scenario: "loaded").waitForList()
        list.assertLocationNotVisible("Tokyo")

        let returnedList = list
            .tapAdd()
            .typeName("Tokyo")
            .typeLatitude("35.6762")
            .typeLongitude("139.6503")
            .submit()

        returnedList.assertLocationVisible("Tokyo")
        returnedList.assertLocationVisible("Amsterdam")
    }

    @MainActor
    func testAddUnnamedLocation_navigatesBackAndShowsUnknown() throws {
        let list = launch(scenario: "loaded").waitForList()

        let returnedList = list
            .tapAdd()
            .typeLatitude("40.7128")
            .typeLongitude("-74.0060")
            .submit()

        returnedList.assertLocationVisible("Amsterdam")
    }

}
