import Foundation
@testable import Places

struct MockCoordinateFormatter: CoordinateFormatter {

    func parse(_ text: String) -> Double? {
        Double(text)
    }

    func format(_ value: Double, fractionDigits: Int = 4) -> String {
        String(format: "%.\(fractionDigits)f", value)
    }
}
