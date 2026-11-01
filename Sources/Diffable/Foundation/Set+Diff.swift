import Foundation

/// The differences between two sets.
///
/// A set has no order, so there are no indexes and no moves: elements are inserted, deleted or, for
/// `Diffable` elements, updated.
///
/// ```
///  old: { A, B, C }                 new: { B, C', D }          (C' = C with other content, same id)
///
///  deletions   { A }                in old, not in new
///  insertions  { D }                in new, not in old
///  updates     [ C -> C' ]          same id in both, other content   (Diffable elements only)
///  B is unchanged and appears nowhere
/// ```
public struct SetChanges<Element: Hashable> {
    /// An element present in both sets, with the same identity but another content.
    public struct Update {
        /// The element in the old set.
        public var old: Element

        /// The element in the new set.
        public var new: Element

        /// Creates an update.
        ///
        /// - Parameters:
        ///   - old: The element in the old set.
        ///   - new: The element in the new set.
        public init(old: Element, new: Element) {
            self.old = old
            self.new = new
        }
    }

    /// The elements only in the new set.
    public var insertions: Set<Element>

    /// The elements only in the old set.
    public var deletions: Set<Element>

    /// The elements in both sets whose content changed. Always empty for a set of plain `Hashable`
    /// elements, because an edited element is then simply a different element.
    public var updates: [Update]

    /// Creates a result.
    ///
    /// - Parameters:
    ///   - insertions: The elements only in the new set.
    ///   - deletions: The elements only in the old set.
    ///   - updates: The elements whose content changed.
    public init(insertions: Set<Element> = [], deletions: Set<Element> = [], updates: [Update] = []) {
        self.insertions = insertions
        self.deletions = deletions
        self.updates = updates
    }

    /// `true` when the two sets are identical.
    public var isEmpty: Bool {
        insertions.isEmpty && deletions.isEmpty && updates.isEmpty
    }
}

extension SetChanges: Equatable {}
extension SetChanges.Update: Equatable {}
extension SetChanges: Sendable where Element: Sendable {}
extension SetChanges.Update: Sendable where Element: Sendable {}

extension Set {
    /// Calculate the elements inserted into and deleted from this set to get `new`.
    ///
    /// ```swift
    /// let changes = Set([1, 2, 3]).diff(Set([2, 3, 4]))
    /// changes.deletions   // [1]
    /// changes.insertions  // [4]
    /// ```
    ///
    /// For elements that are `Diffable`, an edited element is reported as an update instead (see the
    /// overload below).
    ///
    /// - Parameter new: The set to compare to.
    /// - Returns: The insertions and deletions. `updates` is empty.
    public func diff(_ new: Set<Element>) -> SetChanges<Element> {
        SetChanges(insertions: new.subtracting(self), deletions: subtracting(new))
    }
}

extension Set where Element: Diffable {
    /// Calculate the changes between this set and `new`, pairing edited elements by `id`.
    ///
    /// A `Set` holds an edited element next to its old version (they are not equal), so the plain
    /// set difference calls it one deletion plus one insertion. Elements are `Identifiable` here, so an
    /// insertion and a deletion with the same `id` are reported as one update:
    ///
    /// ```swift
    /// let old: Set<Product> = [Product(id: "shoes", quantity: 1), Product(id: "hat", quantity: 2)]
    /// let new: Set<Product> = [Product(id: "shoes", quantity: 3), Product(id: "bag", quantity: 1)]
    ///
    /// let changes = old.diff(new)
    /// changes.updates     // [shoes: quantity 1 -> 3]
    /// changes.deletions   // [hat]
    /// changes.insertions  // [bag]
    /// ```
    ///
    /// ids should be unique in each set. If two elements share an id, they are paired in no particular order.
    ///
    /// - Parameter new: The set to compare to.
    /// - Returns: The insertions, deletions and updates.
    public func diff(_ new: Set<Element>) -> SetChanges<Element> {
        var insertions = new.subtracting(self)
        var deletions = subtracting(new)
        var updates: [SetChanges<Element>.Update] = []

        var deletedByID: [AnyHashable: Element] = [:]
        for element in deletions {
            deletedByID[AnyHashable(element.id)] = element
        }

        for element in insertions {
            let key = AnyHashable(element.id)
            guard let old = deletedByID.removeValue(forKey: key) else {
                continue
            }
            updates.append(SetChanges.Update(old: old, new: element))
            insertions.remove(element)
            deletions.remove(old)
        }

        return SetChanges(insertions: insertions, deletions: deletions, updates: updates)
    }
}
