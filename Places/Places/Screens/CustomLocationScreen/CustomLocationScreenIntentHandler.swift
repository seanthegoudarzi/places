import Foundation

struct CustomLocationScreenIntentHandler: IntentHandler {
    typealias Intent = CustomLocationScreenIntent
    typealias State = CustomLocationScreenState
    typealias Effect = CustomLocationScreenEffect

    private let locationsRepository: LocationsRepository
    private let coordinateFormatter: CoordinateFormatter

    init(locationsRepository: LocationsRepository, coordinateFormatter: CoordinateFormatter) {
        self.locationsRepository = locationsRepository
        self.coordinateFormatter = coordinateFormatter
    }

    func makeInitialState() -> CustomLocationScreenState {
        CustomLocationScreenState(
            latitudePlaceholder: String(
                format: String(localized: "latitude_placeholder"),
                coordinateFormatter.format(52.3547)
            ),
            longitudePlaceholder: String(
                format: String(localized: "longitude_placeholder"),
                coordinateFormatter.format(4.8339)
            )
        )
    }

    func handle(
        _ intent: CustomLocationScreenIntent,
        state: CustomLocationScreenState,
        context: IntentContext<CustomLocationScreenState, CustomLocationScreenEffect>
    ) async {
        var next = state
        switch intent {
        
        case .updateName(let text):
            next.nameText = text
            await context.updateState(next)

        case .updateLatitude(let text):
            next.latitudeText = text
            (next.isAddButtonEnabled, next.validationError) = validate(next)
            await context.updateState(next)

        case .updateLongitude(let text):
            next.longitudeText = text
            (next.isAddButtonEnabled, next.validationError) = validate(next)
            await context.updateState(next)

        case .addLocation:
            guard next.isAddButtonEnabled,
                  let lat = coordinateFormatter.parse(next.latitudeText),
                  let lon = coordinateFormatter.parse(next.longitudeText) else { return }
            let name = next.nameText.trimmingCharacters(in: .whitespaces)
            let location = Location(
                name: name.isEmpty ? nil : name,
                lat: lat,
                long: lon
            )
            await locationsRepository.addLocation(location)
            await context.emitEffect(.navigateToRoot(location))
        }
    }

    private func validate(_ state: CustomLocationScreenState) -> (isEnabled: Bool, error: String?) {
        if state.latitudeText.isEmpty || state.longitudeText.isEmpty {
            return (false, nil)
        }
        guard let lat = coordinateFormatter.parse(state.latitudeText) else {
            return (false, String(localized: "invalid_latitude"))
        }
        guard let lon = coordinateFormatter.parse(state.longitudeText) else {
            return (false, String(localized: "invalid_longitude"))
        }
        if lat < -90 || lat > 90 {
            return (false, String(localized: "latitude_out_of_range"))
        }
        if lon < -180 || lon > 180 {
            return (false, String(localized: "longitude_out_of_range"))
        }
        return (true, nil)
    }
}
