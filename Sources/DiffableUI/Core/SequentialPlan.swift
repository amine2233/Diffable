import Foundation

/// Turns `ListChanges` into an ordered list of operations where **every index is relative to the
/// state left by the previous operation**, which is how `NSTableView`, `NSOutlineView`, `NSMenu` and
/// stack views work.
///
/// ## How the plan is built
///
/// 1. Remove the deleted items, highest index first (so lower indexes stay valid).
/// 2. Compute the *target* order: inserted slots, moved items at their destination, and the items that
///    stay in place in their old relative order.
/// 3. Walk the target from index 0; each position is fixed once and never touched again:
///    insert a new item there, or move the wanted item there, or do nothing if it already is.
///
/// ```
///  old: [ a  b  c  d ]      new: [ d  b  x ]      a, c deleted · x inserted · d moved to the front
///
///  1. remove(2)                           [ a  b  d ]
///     remove(0)                           [ b  d ]
///  2. target                              [ d  b  x ]
///  3. i=0 wants d, has b   -> move(1 -> 0)  [ d  b ]
///     i=1 wants b, has b   -> nothing
///     i=2 wants x (new)    -> insert(2)     [ d  b  x ]
/// ```
///
/// The test suite replays the plan on thousands of random lists (with and without duplicate keys)
/// and checks it always rebuilds the new list.
///
/// Updates are not part of the plan: they do not change positions.
public struct SequentialPlan: Equatable, Sendable {
    public enum Operation: Equatable, Sendable {
        case remove(Int)
        case insert(Int)
        case move(from: Int, to: Int)
    }

    public let operations: [Operation]

    /// - Parameters:
    ///   - changes: The diff between the old and the new list.
    ///   - oldCount: Number of items in the OLD list.
    ///   - newCount: Number of items in the NEW list.
    public init(changes: ListChanges, oldCount: Int, newCount: Int) {
        var operations: [Operation] = []

        let removed = Set(changes.deletions)
        for index in changes.deletions.sorted(by: >) {
            operations.append(.remove(index))
        }

        let inserted = Set(changes.insertions)
        let movedFrom = Set(changes.moves.map { $0.from })
        var moveSources: [Int: Int] = [:]
        for move in changes.moves {
            moveSources[move.to] = move.from
        }

        let placeholder = -1
        var staying = (0 ..< oldCount).filter { !removed.contains($0) && !movedFrom.contains($0) }
            .makeIterator()
        let target: [Int] = (0 ..< newCount).map { newIndex in
            if inserted.contains(newIndex) {
                return placeholder
            }
            return moveSources[newIndex] ?? staying.next() ?? placeholder
        }

        var tokens = (0 ..< oldCount).filter { !removed.contains($0) }

        for (newIndex, wanted) in target.enumerated() {
            if wanted == placeholder {
                tokens.insert(placeholder, at: min(newIndex, tokens.count))
                operations.append(.insert(newIndex))
            } else if newIndex < tokens.count, tokens[newIndex] == wanted {
                continue
            } else if let current = tokens.firstIndex(of: wanted) {
                tokens.remove(at: current)
                tokens.insert(wanted, at: min(newIndex, tokens.count))
                operations.append(.move(from: current, to: newIndex))
            }
        }

        self.operations = operations
    }

    /// Runs the plan against a view, in order.
    ///
    /// - Parameters:
    ///   - remove: Remove the item at this index.
    ///   - insert: Insert a new item at this index (its content is `new[index]`).
    ///   - move: Move the item currently at `from` so it ends at `to`.
    public func perform(remove: (Int) -> Void, insert: (Int) -> Void, move: (Int, Int) -> Void) {
        for operation in operations {
            switch operation {
            case let .remove(index):
                remove(index)
            case let .insert(index):
                insert(index)
            case let .move(from, to):
                move(from, to)
            }
        }
    }
}
