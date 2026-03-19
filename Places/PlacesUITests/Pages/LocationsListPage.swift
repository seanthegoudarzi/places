import XCTest

struct LocationsListPage {
    let app: XCUIApplication

    var list: XCUIElement { app.collectionViews["locationsList"] }
    var emptyView: XCUIElement { app.otherElements["emptyView"] }
    var addButton: XCUIElement { app.buttons["addLocationButton"] }
    var navigationBar: XCUIElement { app.navigationBars["Places"] }

    @discardableResult
    func waitForList(timeout: TimeInterval = 5) -> Self {
        XCTAssertTrue(list.waitForExistence(timeout: timeout), "Expected locations list to appear")
        return self
    }

    @discardableResult
    func waitForEmpty(timeout: TimeInterval = 5) -> Self {
        XCTAssertTrue(emptyView.waitForExistence(timeout: timeout), "Expected empty view to appear")
        return self
    }

    func assertLocationVisible(_ name: String, timeout: TimeInterval = 5) {
        XCTAssertTrue(
            app.staticTexts[name].waitForExistence(timeout: timeout),
            "Expected '\(name)' to be visible in the list"
        )
    }

    func assertLocationNotVisible(_ name: String) {
        XCTAssertFalse(app.staticTexts[name].exists, "Expected '\(name)' to NOT be in the list")
    }

    func tapAdd() -> CustomLocationPage {
        addButton.tap()
        let page = CustomLocationPage(app: app)
        page.waitForForm()
        return page
    }
}
