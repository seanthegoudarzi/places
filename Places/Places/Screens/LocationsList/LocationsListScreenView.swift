import SwiftUI

final class LocationsListScreenViewModel: ViewModel<LocationsListScreenIntent, LocationsListScreenState, LocationsListScreenEffect> {
    init(
        intentHandler: LocationsScreenIntentHandler,
        initialState: LocationsListScreenState = LocationsListScreenState()
    ) {
        super.init(intentHandler: intentHandler, initialState: initialState)
        
        Task {
            await handle(.fetchLocations)
        }
    }
}


struct LocationsListScreenView: View {
    @State private var viewModel: LocationsListScreenViewModel = DependencyContainer.shared.resolve()
    @Environment(\.openURL) private var openURL

    let onNavigateToAddLocationRequested: () -> Void

    init(
        onNavigateToAddLocationRequested: @escaping () -> Void
    ) {
        self.onNavigateToAddLocationRequested = onNavigateToAddLocationRequested
    }

    var body: some View {
        LocationsListContentView(
            state: viewModel.state,
            onIntent: {
                await viewModel.handle($0)
            }
        )
        .onAppear {
            Task {
                await viewModel.handle(.fetchLocations)
            }
        }
        .onReceive(viewModel.effectPublisher) { effect in
            switch effect {
            case .openURL(let url):
                openURL(url) { accepted in
                    guard !accepted else { return }
                    Task { await viewModel.handle(.wikipediaOpenFailed) }
                }
            case .navigateToAddLocationPage:
                onNavigateToAddLocationRequested()
            }
        }
    }
}

private struct LocationsListContentView: View {
    let state: LocationsListScreenState
    let onIntent: (LocationsListScreenIntent) async -> Void

    var body: some View {
        Group {
            if let errorMessage = state.errorMessage {
                errorView(message: errorMessage)
            } else if state.isLoading, state.locations == nil {
                loadingView
            } else if let locations = state.locations {
                if locations.isEmpty {
                    emptyView
                } else {
                    LocationsList(
                        items: locations,
                        onLocationItemTapped: { locationDisplayItem in
                            Task {
                                await onIntent(.openInWikipedia(locationDisplayItem.location))
                            }
                        },
                        onLocationsListRefreshRequested: {
                            await onIntent(.fetchLocations)
                        }
                    )
                }
            }
        }
        .navigationTitle(String(localized: "locations_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await onIntent(.addLocationTapped) }
                } label: {
                    Label(String(localized: "add_custom_location"), systemImage: "plus.circle")
                }
                .accessibilityHint(String(localized: "add_custom_location"))
                .accessibilityIdentifier("addLocationButton")
            }
        }
        .alert(
            String(localized: "wikipedia_not_installed_title"),
            isPresented: Binding(
                get: { state.showWikipediaNotInstalledAlert },
                set: { _ in Task { await onIntent(.wikipediaAlertDismissed) } }
            )
        ) {
            Button(String(localized: "ok"), role: .cancel) {}
        } message: {
            Text("wikipedia_not_installed_message")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("no_locations_title", tableName: nil)
                .font(.headline)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            Text("no_locations_message", tableName: nil)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("emptyView")
    }

    private var loadingView: some View {
        List {
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("loading_locations")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.insetGrouped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "loading_locations"))
        .accessibilityIdentifier("loadingView")
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("error_loading", tableName: nil)
                    .font(.headline)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            retryButton
                .padding(.horizontal, 16)
                .accessibilityLabel(String(localized: "retry"))
                .accessibilityHint(String(localized: "error_loading"))
                .accessibilityIdentifier("retryButton")
            
            Spacer()
        }
    }

    @ViewBuilder
    private var retryButton: some View {
        if #available(iOS 26.0, *) {
            Button {
                Task { await onIntent(.fetchLocations) }
            } label: {
                Text("retry", tableName: nil)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button {
                Task { await onIntent(.fetchLocations) }
            } label: {
                Text("retry", tableName: nil)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct LocationsList: View {

    let items: [LocationDisplayItem]
    let onLocationItemTapped: (LocationDisplayItem) -> Void
    let onLocationsListRefreshRequested: () async -> Void
    
    var body: some View {
        List(items) { item in
            Button {
                onLocationItemTapped(item)
            } label: {
                LocationRowView(item: item)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
        .refreshable {
            let start = ContinuousClock.now
            await onLocationsListRefreshRequested()
            let elapsed = ContinuousClock.now - start
            let minDisplayTime: Duration = .milliseconds(500)
            if elapsed < minDisplayTime {
                try? await Task.sleep(for: minDisplayTime - elapsed)
            }
        }
        .accessibilityIdentifier("locationsList")
    }
}

#Preview("Loading") {
    NavigationStack {
        LocationsListContentView(
            state: LocationsListScreenState(isLoading: true),
            onIntent: { _ in }
        )
    }
}

#Preview("Loaded - Empty") {
    NavigationStack {
        LocationsListContentView(
            state: LocationsListScreenState(locations: []),
            onIntent: { _ in }
        )
    }
}

#Preview("Loaded - With Locations") {
    NavigationStack {
        LocationsListContentView(
            state: LocationsListScreenState(
                locations: [
                    LocationDisplayItem(location: Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215), coordinatesText: "52.3547, 4.8339", accessibilityLabel: "Amsterdam, 52.3547, 4.8339"),
                    LocationDisplayItem(location: Location(name: "Madrid", lat: 40.4380638, long: -3.7495758), coordinatesText: "40.4381, -3.7496", accessibilityLabel: "Madrid, 40.4381, -3.7496"),
                    LocationDisplayItem(location: Location(name: "San Francisco", lat: 37.7749295, long: -122.4194155), coordinatesText: "37.7749, -122.4194", accessibilityLabel: "San Francisco, 37.7749, -122.4194"),
                    LocationDisplayItem(location: Location(name: nil, lat: 48.8566969, long: 2.3514616), coordinatesText: "48.8567, 2.3515", accessibilityLabel: "Unknown Location, 48.8567, 2.3515"),
                    LocationDisplayItem(location: Location(name: "Tokyo", lat: 35.6762, long: 139.6503), coordinatesText: "35.6762, 139.6503", accessibilityLabel: "Tokyo, 35.6762, 139.6503")
                ]
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("Error - Network") {
    NavigationStack {
        LocationsListContentView(
            state: LocationsListScreenState(
                errorMessage: "Unable to connect to the server. Please check your internet connection."
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("Error - Generic") {
    NavigationStack {
        LocationsListContentView(
            state: LocationsListScreenState(errorMessage: "Something went wrong"),
            onIntent: { _ in }
        )
    }
}
