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
                updated.locations = await withTaskGroup(of: (Int, LocationDisplayItem).self, body: { taskGroup in
                    for (locationIndex, location) in locations.enumerated() {
                        taskGroup.addTask {
                            return (locationIndex, await makeDisplayItem(from: location, using: coordinateFormatter))
                        }
                    }
                    var locations: [LocationDisplayItem?] = Array(repeating: nil, count: locations.count)
                    for await result in taskGroup {
                        locations[result.0] = result.1
                    }
                    return locations.compactMap { $0 }
                })
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

    @concurrent
    private func makeDisplayItem(
        from location: Location,
        using coordinateFormatter: CoordinateFormatter
    ) async -> LocationDisplayItem {
        async let lat = coordinateFormatter.format(location.lat)
        async let lon = coordinateFormatter.format(location.long)
        
        let (formattedLat, formattedLon) = await (lat, lon)
        
        return LocationDisplayItem(
            location: location,
            coordinatesText: "\(formattedLat), \(formattedLon)",
            accessibilityLabel: await String(
                format: String(localized: "location_accessibility_label"),
                location.displayName,
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
