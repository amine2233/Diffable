import Foundation

/// The differences between two dictionaries.
///
/// Keys are the identity and values are the content, so a key in both dictionaries with different values
/// is an update. There is no order, hence no indexes and no moves.
///
/// ```
///  old: [a: 1, b: 2, c: 3]          new: [b: 2, c: 30, d: 4]
///
///  deletions   [a: 1]               key only in old       (with its old value)
///  insertions  [d: 4]               key only in new       (with its new value)
///  updates     [c: 3 -> 30]         key in both, other value
///  b is unchanged and appears nowhere
/// ```
public struct DictionaryChanges<Key: Hashable, Value> {
    /// A key present in both dictionaries with two different values.
    public struct Update {
        /// The value in the old dictionary.
        public var old: Value

        /// The value in the new dictionary.
        public var new: Value

        /// Creates an update.
        ///
        /// - Parameters:
        ///   - old: The value in the old dictionary.
        ///   - new: The value in the new dictionary.
        public init(old: Value, new: Value) {
            self.old = old
            self.new = new
        }
    }

    /// The keys only in the new dictionary, with their values.
    public var insertions: [Key: Value]

    /// The keys only in the old dictionary, with their old values.
    public var deletions: [Key: Value]

    /// The keys in both dictionaries whose value changed.
    public var updates: [Key: Update]

    /// Creates a result.
    ///
    /// - Parameters:
    ///   - insertions: The keys only in the new dictionary.
    ///   - deletions: The keys only in the old dictionary.
    ///   - updates: The keys whose value changed.
    public init(
        insertions: [Key: Value] = [:],
        deletions: [Key: Value] = [:],
        updates: [Key: Update] = [:]
    ) {
        self.insertions = insertions
        self.deletions = deletions
        self.updates = updates
    }

    /// `true` when the two dictionaries are identical.
    public var isEmpty: Bool {
        insertions.isEmpty && deletions.isEmpty && updates.isEmpty
    }
}

extension DictionaryChanges.Update: Equatable where Value: Equatable {}
extension DictionaryChanges: Equatable where Value: Equatable {}
extension DictionaryChanges.Update: Sendable where Value: Sendable {}
extension DictionaryChanges: Sendable where Key: Sendable, Value: Sendable {}

extension Dictionary where Value: Equatable {
    /// Calculate the keys inserted, deleted and updated to get from this dictionary to `new`.
    ///
    /// ```swift
    /// let old = ["a": 1, "b": 2, "c": 3]
    /// let new = ["b": 2, "c": 30, "d": 4]
    ///
    /// let changes = old.diff(new)
    /// changes.deletions   // ["a": 1]
    /// changes.insertions  // ["d": 4]
    /// changes.updates     // ["c": Update(old: 3, new: 30)]
    /// ```
    ///
    /// Applying the result to `self` always gives `new`: remove the deletions, add the insertions and replace
    /// the updated values.
    ///
    /// - Parameter new: The dictionary to compare to.
    /// - Returns: The insertions, deletions and updates, in O(n).
    public func diff(_ new: [Key: Value]) -> DictionaryChanges<Key, Value> {
        var changes = DictionaryChanges<Key, Value>()

        for (key, oldValue) in self {
            guard let newValue = new[key] else {
                changes.deletions[key] = oldValue
                continue
            }
            if oldValue != newValue {
                changes.updates[key] = .init(old: oldValue, new: newValue)
            }
        }
        for (key, newValue) in new where self[key] == nil {
            changes.insertions[key] = newValue
        }

        return changes
    }
}
