import Foundation

enum LocationsListScreenIntent {
    case fetchLocations
    case openInWikipedia(Location)
    case wikipediaOpenFailed
    case wikipediaAlertDismissed
    case addLocationTapped
}
