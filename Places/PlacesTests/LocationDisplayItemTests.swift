import XCTest
@testable import Places

@MainActor
final class LocationDisplayItemTests: XCTestCase {

    func testDisplayName_withName_returnsName() {
        let location = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let item = LocationDisplayItem(
            location: location,
            coordinatesText: "52.3547, 4.8339",
            accessibilityLabel: ""
        )

        XCTAssertEqual(item.displayName, "Amsterdam")
    }

    func testDisplayName_withoutName_returnsUnknownLocation() {
        let location = Location(name: nil, lat: 40.4380638, long: -3.7495758)
        let item = LocationDisplayItem(
            location: location,
            coordinatesText: "40.4381, -3.7496",
            accessibilityLabel: ""
        )

        XCTAssertEqual(item.displayName, "Unknown Location")
    }
}
