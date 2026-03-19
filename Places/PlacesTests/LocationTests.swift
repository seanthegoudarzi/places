import XCTest
@testable import Places

@MainActor
final class LocationTests: XCTestCase {

    func testDecoding_withName() throws {
        let json = """
        {"name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215}
        """.data(using: .utf8)!

        let location = try JSONDecoder().decode(Location.self, from: json)

        XCTAssertEqual(location.name, "Amsterdam")
        XCTAssertEqual(location.lat, 52.3547498, accuracy: 0.0001)
        XCTAssertEqual(location.long, 4.8339215, accuracy: 0.0001)
        XCTAssertEqual(location.displayName, "Amsterdam")
    }

    func testDecoding_withoutName() throws {
        let json = """
        {"lat": 40.4380638, "long": -3.7495758}
        """.data(using: .utf8)!

        let location = try JSONDecoder().decode(Location.self, from: json)

        XCTAssertNil(location.name)
        XCTAssertEqual(location.lat, 40.4380638, accuracy: 0.0001)
        XCTAssertEqual(location.long, -3.7495758, accuracy: 0.0001)
        XCTAssertEqual(location.displayName, "Unknown Location")
    }

    func testDecoding_locationResponse() throws {
        let json = """
        {
          "locations": [
            {"name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215},
            {"name": "Mumbai", "lat": 19.0823998, "long": 72.8111468},
            {"lat": 40.4380638, "long": -3.7495758}
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LocationsResponse.self, from: json)

        XCTAssertEqual(response.locations.count, 3)
        XCTAssertEqual(response.locations[0].name, "Amsterdam")
        XCTAssertNil(response.locations[2].name)
    }

    func testDecoding_malformedJSON_throws() {
        let json = """
        {"name": "Amsterdam", "lat": "not-a-number", "long": 4.8339215}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(Location.self, from: json))
    }

    func testID_isStableForSameContent() {
        let loc1 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let loc2 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)

        XCTAssertEqual(loc1.id, loc2.id, "Same content should produce the same id")
    }

    func testID_isDifferentForDifferentContent() {
        let loc1 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let loc2 = Location(name: "Madrid", lat: 40.4380638, long: -3.7495758)

        XCTAssertNotEqual(loc1.id, loc2.id)
    }

    func testID_isStableAcrossDecodes() throws {
        let json = """
        {"name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215}
        """.data(using: .utf8)!

        let first = try JSONDecoder().decode(Location.self, from: json)
        let second = try JSONDecoder().decode(Location.self, from: json)

        XCTAssertEqual(first.id, second.id, "Decoding the same JSON twice should produce the same id")
    }

    func testHashable_equalLocationsHaveSameHash() {
        let loc1 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let loc2 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)

        XCTAssertEqual(loc1.hashValue, loc2.hashValue)
    }

    func testEquatable_sameContentIsEqual() {
        let loc1 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let loc2 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)

        XCTAssertEqual(loc1, loc2, "Locations with same content should be equal regardless of id")
    }

    func testEquatable_differentContentIsNotEqual() {
        let loc1 = Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215)
        let loc2 = Location(name: "Madrid", lat: 40.4380638, long: -3.7495758)

        XCTAssertNotEqual(loc1, loc2)
    }
}
