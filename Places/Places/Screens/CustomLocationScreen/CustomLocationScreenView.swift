import SwiftUI

final class CustomLocationScreenViewModel: ViewModel<CustomLocationScreenIntent, CustomLocationScreenState, CustomLocationScreenEffect> {
    init(
        intentHandler: CustomLocationScreenIntentHandler,
        initialState: CustomLocationScreenState = CustomLocationScreenState()
    ) {
        super.init(intentHandler: intentHandler, initialState: initialState)
    }
}


struct CustomLocationScreenView: View {
    @State private var viewModel: CustomLocationScreenViewModel = DependencyContainer.shared.resolve()
    
    let onNavigateToRootRequested: () -> Void

    init(onNavigateToRootRequested: @escaping () -> Void) {
        self.onNavigateToRootRequested = onNavigateToRootRequested
    }

    var body: some View {
        CustomLocationContentView(
            state: viewModel.state,
            onIntent: { intent in
                Task {
                    await viewModel.handle(intent)
                }
            }
        )
        .onReceive(viewModel.effectPublisher) { effect in
            switch effect {
            case .navigateToRoot:
                onNavigateToRootRequested()
            }
        }
    }
}

private struct CustomLocationContentView: View {
    let state: CustomLocationScreenState
    let onIntent: (CustomLocationScreenIntent) -> Void

    var body: some View {
        Form {
            Section {
                TextField(
                    String(localized: "name_placeholder"),
                    text: Binding(
                        get: { state.nameText },
                        set: { onIntent(.updateName($0)) }
                    )
                )
                .accessibilityLabel(String(localized: "name_placeholder"))
                .accessibilityIdentifier("nameTextField")

                TextField(
                    state.latitudePlaceholder,
                    text: Binding(
                        get: { state.latitudeText },
                        set: { onIntent(.updateLatitude($0)) }
                    )
                )
                .keyboardType(.decimalPad)
                .accessibilityLabel(state.latitudePlaceholder)
                .accessibilityValue(state.latitudeText.isEmpty ? "" : state.latitudeText)
                .accessibilityIdentifier("latitudeTextField")

                TextField(
                    state.longitudePlaceholder,
                    text: Binding(
                        get: { state.longitudeText },
                        set: { onIntent(.updateLongitude($0)) }
                    )
                )
                .keyboardType(.decimalPad)
                .accessibilityLabel(state.longitudePlaceholder)
                .accessibilityValue(state.longitudeText.isEmpty ? "" : state.longitudeText)
                .accessibilityIdentifier("longitudeTextField")
            } header: {
                Text("coordinates_label", tableName: nil)
            } footer: {
                if let error = state.validationError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                        Text(error)
                    }
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("validationError")
                }
            }

            Section {
                Button(String(localized: "add_location")) {
                    onIntent(.addLocation)
                }
                .disabled(!state.isAddButtonEnabled)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(String(localized: "add_location"))
                .accessibilityHint(String(localized: "add_location_accessibility_hint"))
                .accessibilityIdentifier("addLocationSubmitButton")
            }
        }
        .navigationTitle(String(localized: "custom_location_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: state.validationError) { _, newError in
            if let error = newError {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: error
                )
            }
        }
    }
}

#Preview("Empty Form") {
    NavigationStack {
        CustomLocationContentView(
            state: CustomLocationScreenState(
                latitudePlaceholder: "Latitude (e.g. 52.3547)",
                longitudePlaceholder: "Longitude (e.g. 4.8339)"
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("Partially Filled") {
    NavigationStack {
        CustomLocationContentView(
            state: CustomLocationScreenState(
                nameText: "Paris",
                latitudeText: "48.8566",
                latitudePlaceholder: "Latitude (e.g. 52.3547)",
                longitudePlaceholder: "Longitude (e.g. 4.8339)"
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("Valid Input - Ready to Add") {
    NavigationStack {
        CustomLocationContentView(
            state: CustomLocationScreenState(
                nameText: "Paris",
                latitudeText: "48.8566",
                longitudeText: "2.3522",
                isAddButtonEnabled: true,
                latitudePlaceholder: "Latitude (e.g. 52.3547)",
                longitudePlaceholder: "Longitude (e.g. 4.8339)"
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("Invalid Latitude") {
    NavigationStack {
        CustomLocationContentView(
            state: CustomLocationScreenState(
                nameText: "Test Location",
                latitudeText: "invalid",
                longitudeText: "2.3522",
                validationError: "Latitude must be a valid number between -90 and 90",
                latitudePlaceholder: "Latitude (e.g. 52.3547)",
                longitudePlaceholder: "Longitude (e.g. 4.8339)"
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("Invalid Longitude") {
    NavigationStack {
        CustomLocationContentView(
            state: CustomLocationScreenState(
                nameText: "Test Location",
                latitudeText: "48.8566",
                longitudeText: "200",
                validationError: "Longitude must be a valid number between -180 and 180",
                latitudePlaceholder: "Latitude (e.g. 52.3547)",
                longitudePlaceholder: "Longitude (e.g. 4.8339)"
            ),
            onIntent: { _ in }
        )
    }
}

#Preview("No Name - Valid Coordinates") {
    NavigationStack {
        CustomLocationContentView(
            state: CustomLocationScreenState(
                latitudeText: "40.7128",
                longitudeText: "-74.0060",
                isAddButtonEnabled: true,
                latitudePlaceholder: "Latitude (e.g. 52.3547)",
                longitudePlaceholder: "Longitude (e.g. 4.8339)"
            ),
            onIntent: { _ in }
        )
    }
}
