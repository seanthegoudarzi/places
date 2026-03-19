import Foundation

struct LocationsListScreenState {
    var isLoading: Bool = false
    var locations: [LocationDisplayItem]? = nil
    var errorMessage: String? = nil
    var showWikipediaNotInstalledAlert: Bool = false
}
