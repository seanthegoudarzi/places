import SwiftUI

struct LocationRowView: View, Equatable {
    let item: LocationDisplayItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(item.coordinatesText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .imageScale(.small)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(String(localized: "location_accessibility_hint"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("locationRow_\(item.displayName)")
    }
}

#Preview {
    List {
        LocationRowView(item: LocationDisplayItem(
            location: Location(name: "Amsterdam", lat: 52.3547498, long: 4.8339215),
            coordinatesText: "52.3547, 4.8339",
            accessibilityLabel: "Amsterdam, latitude 52.3547, longitude 4.8339"
        ))
        LocationRowView(item: LocationDisplayItem(
            location: Location(name: nil, lat: 40.4380638, long: -3.7495758),
            coordinatesText: "40.4381, -3.7496",
            accessibilityLabel: "Unknown Location, latitude 40.4381, longitude -3.7496"
        ))
    }
}
