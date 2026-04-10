import Foundation

struct Location: Codable, Identifiable, Hashable, Sendable {
    let name: String?
    let lat: Double
    let long: Double

    var id: String { "\(name ?? "")|\(lat)|\(long)" }

    enum CodingKeys: String, CodingKey {
        case name, lat, long
    }
}

