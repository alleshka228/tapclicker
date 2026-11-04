import Foundation

/// Компактное форматирование больших чисел: 1 234 -> "1.23K", 5 400 000 -> "5.4M"
enum Format {
    private static let units: [(threshold: Double, suffix: String)] = [
        (1e15, "Q"),
        (1e12, "T"),
        (1e9, "B"),
        (1e6, "M"),
        (1e3, "K")
    ]

    static func short(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let magnitude = abs(value)
        for unit in units where magnitude >= unit.threshold {
            return trimmed(value / unit.threshold) + unit.suffix
        }
        return trimmed(value)
    }

    static func trimmed(_ value: Double) -> String {
        if abs(value) >= 100 {
            return String(format: "%.0f", value)
        }
        var text = String(format: "%.2f", value)
        while text.contains("."), text.hasSuffix("0") || text.hasSuffix(".") {
            text.removeLast()
        }
        return text
    }
}
