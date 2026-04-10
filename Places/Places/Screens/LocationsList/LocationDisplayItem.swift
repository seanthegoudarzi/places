import Foundation

struct LocationDisplayItem: Identifiable, Hashable {
    let location: Location
    let coordinatesText: String
    let accessibilityLabel: String

    var id: String { location.id }
    var displayName: String { location.name ?? String(localized: "unknown_location") }
}
