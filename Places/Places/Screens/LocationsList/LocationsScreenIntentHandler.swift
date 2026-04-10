import Foundation

struct LocationsScreenIntentHandler: IntentHandler {
    typealias Intent = LocationsListScreenIntent
    typealias State = LocationsListScreenState
    typealias Effect = LocationsListScreenEffect

    private let locationsRepository: LocationsRepository
    private let coordinateFormatter: CoordinateFormatter

    init(locationsRepository: LocationsRepository, coordinateFormatter: CoordinateFormatter) {
        self.locationsRepository = locationsRepository
        self.coordinateFormatter = coordinateFormatter
    }

    func handle(
        _ intent: LocationsListScreenIntent,
        state: LocationsListScreenState,
        context: IntentContext<LocationsListScreenState, LocationsListScreenEffect>
    ) async {
        switch intent {
        case .fetchLocations:
            var newState = state
            newState.isLoading = true
            newState.errorMessage = nil
            await context.updateState(newState)

            do {
                let locations = try await locationsRepository.fetchLocations()
                var updated = newState
                updated.isLoading = false
                updated.locations = locations.map { makeDisplayItem(from: $0, using: coordinateFormatter) }
                await context.updateState(updated)
            } catch {
                var failed = newState
                failed.isLoading = false
                failed.errorMessage = error.localizedDescription
                await context.updateState(failed)
            }

        case .openInWikipedia(let location):
            guard let url = wikipediaDeepLinkURL(for: location) else { return }
            await context.emitEffect(.openURL(url))

        case .wikipediaOpenFailed:
            var updatedState = state
            updatedState.showWikipediaNotInstalledAlert = true
            await context.updateState(updatedState)

        case .wikipediaAlertDismissed:
            var updatedState = state
            updatedState.showWikipediaNotInstalledAlert = false
            await context.updateState(updatedState)

        case .addLocationTapped:
            await context.emitEffect(.navigateToAddLocationPage)
        }
    }

    private func makeDisplayItem(
        from location: Location,
        using coordinateFormatter: CoordinateFormatter
    ) -> LocationDisplayItem {
        let formattedLat = coordinateFormatter.format(location.lat)
        let formattedLon = coordinateFormatter.format(location.long)

        return LocationDisplayItem(
            location: location,
            coordinatesText: "\(formattedLat), \(formattedLon)",
            accessibilityLabel: String(
                format: String(localized: "location_accessibility_label"),
                location.name ?? String(localized: "unknown_location"),
                formattedLat,
                formattedLon
            )
        )
    }

    private func wikipediaDeepLinkURL(for location: Location) -> URL? {
        var components = URLComponents()
        components.scheme = "wikipedia"
        components.host = "places"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.lat)),
            URLQueryItem(name: "longitude", value: String(location.long))
        ]
        return components.url
    }
}
