import Foundation

protocol CoordinateFormatter: Sendable {
    func parse(_ text: String) -> Double?
    func format(_ value: Double, fractionDigits: Int) -> String
}

extension CoordinateFormatter {
    func format(_ value: Double) -> String {
        format(value, fractionDigits: 4)
    }
}

/// Default implementation that uses locale-aware parsing (current locale with
/// POSIX fallback) and always formats with a dot decimal separator for display.
struct DefaultCoordinateFormatter: CoordinateFormatter {

    func parse(_ text: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false

        formatter.locale = .current
        if let value = formatter.number(from: text)?.doubleValue {
            return value
        }

        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.number(from: text)?.doubleValue
    }

    func format(_ value: Double, fractionDigits: Int = 4) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = false
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
