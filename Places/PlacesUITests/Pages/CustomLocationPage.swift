import XCTest

struct CustomLocationPage {
    let app: XCUIApplication

    var nameField: XCUIElement { app.textFields["nameTextField"] }
    var latitudeField: XCUIElement { app.textFields["latitudeTextField"] }
    var longitudeField: XCUIElement { app.textFields["longitudeTextField"] }
    var submitButton: XCUIElement { app.buttons["addLocationSubmitButton"] }
    var navigationBar: XCUIElement { app.navigationBars["Custom Location"] }

    func waitForForm(timeout: TimeInterval = 5) {
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout), "Expected custom location form to appear")
    }

    @discardableResult
    func typeName(_ text: String) -> Self {
        nameField.tap()
        nameField.typeText(text)
        return self
    }

    @discardableResult
    func typeLatitude(_ text: String) -> Self {
        latitudeField.tap()
        latitudeField.typeText(text)
        return self
    }

    @discardableResult
    func typeLongitude(_ text: String) -> Self {
        longitudeField.tap()
        longitudeField.typeText(text)
        return self
    }

    func submit() -> LocationsListPage {
        submitButton.tap()
        let page = LocationsListPage(app: app)
        page.waitForList()
        return page
    }

    func tapBack() -> LocationsListPage {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        return LocationsListPage(app: app)
    }
}
