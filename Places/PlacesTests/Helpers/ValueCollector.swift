import Foundation

@MainActor
final class ValueCollector<T> {
    private(set) var values: [T] = []

    nonisolated init() {}

    func collect(_ value: T) {
        values.append(value)
    }

    var first: T? { values.first }
    var last: T? { values.last }
    var count: Int { values.count }
    var isEmpty: Bool { values.isEmpty }
}
