import Foundation

/// The identity of a node in a diff result: a type-erased, `Sendable` wrapper around an `Identifiable.id`.
///
/// `AnyHashable` cannot be `Sendable`, so results that must cross tasks (`TreeChange`, `TreePath`,
/// `SnapshotItemID`) store a `DiffID` instead. Equality is the one of the wrapped values, and it is type
/// aware, so `1` (an `Int`) and `"1"` (a `String`) are different ids.
///
/// ```swift
/// DiffID(42) == DiffID(42)        // true
/// DiffID(42) == DiffID("42")      // false, different types
/// DiffID("src") == "src"          // true, string literals convert
/// ```
public struct DiffID: Hashable, Sendable, CustomStringConvertible {
    private let storage: any Hashable & Sendable

    /// Wraps an id.
    ///
    /// - Parameter value: Any `Hashable` and `Sendable` value, usually the `id` of a model.
    public init(_ value: some Hashable & Sendable) {
        if let nested = value as? DiffID {
            self.storage = nested.storage
        } else {
            self.storage = value
        }
    }

    public static func == (lhs: DiffID, rhs: DiffID) -> Bool {
        AnyHashable(lhs.storage) == AnyHashable(rhs.storage)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(storage))
    }

    /// The description of the wrapped id, for example `src` for `DiffID("src")`.
    public var description: String {
        "\(storage)"
    }
}

extension DiffID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension DiffID: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension Diffable {
    /// The `id` as a `DiffID`.
    public var diffID: DiffID {
        DiffID(id)
    }
}
