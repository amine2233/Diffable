#if SWIFT_PACKAGE
import Diffable
#endif
import Foundation

/// The result of diffing two flat lists, as plain integers, independent of any view.
///
/// Every UI adapter (`UITableView`, `NSCollectionView`, `NSMenu`...) is built on this value.
///
/// ## Two index spaces
///
/// ```
///    old: [ A  B  C ]                         new: [ B  C' D ]
///           0  1  2                                  0  1  2
///
///    deletions  [0]       index in the OLD list     (A is gone)
///    moves      []        from OLD -> to NEW
///    insertions [2]       index in the NEW list     (D is new)
///    updates    [1]       index in the NEW list     (C changed content)
/// ```
///
/// Views whose batch API is *simultaneous* (UIKit, `NSCollectionView`) take the indexes as they are.
/// Views whose API is *sequential* (`NSTableView`, `NSMenu`, stack views) go through `SequentialPlan`.
public struct ListChanges: Sendable {
    /// The NEW indexes of the items whose content changed.
    public var updates: [Int]
    /// The NEW indexes of the inserted items.
    public var insertions: [Int]
    /// The OLD indexes of the deleted items.
    public var deletions: [Int]
    /// The moves, from an OLD index to a NEW index.
    public var moves: [(from: Int, to: Int)]

    /// Creates changes from the four lists.
    ///
    /// - Parameters:
    ///   - updates: The NEW indexes of the items whose content changed.
    ///   - insertions: The NEW indexes of the inserted items.
    ///   - deletions: The OLD indexes of the deleted items.
    ///   - moves: The moves, from an OLD index to a NEW index.
    public init(
        updates: [Int] = [],
        insertions: [Int] = [],
        deletions: [Int] = [],
        moves: [(from: Int, to: Int)] = []
    ) {
        self.updates = updates
        self.insertions = insertions
        self.deletions = deletions
        self.moves = moves
    }

    /// Creates changes from the tuple returned by `Array.diff(_:algorithm:)`.
    ///
    /// - Parameter changes: The updates, insertions, deletions and moves of a diff.
    public init(_ changes: (updates: [Int], insertions: [Int], deletions: [Int], moves: [(Int, Int)])) {
        self.init(
            updates: changes.updates,
            insertions: changes.insertions,
            deletions: changes.deletions,
            moves: changes.moves.map { (from: $0.0, to: $0.1) }
        )
    }

    /// The changes of one level of siblings of a `treeDiff` result.
    ///
    /// ```
    ///  TreeChange.kind == .delete        -> deletions  [index]   (OLD)
    ///  TreeChange.kind == .insert        -> insertions [index]   (NEW)
    ///  TreeChange.kind == .update        -> updates    [index]   (NEW)
    ///  TreeChange.movedFrom != nil       -> moves      (movedFrom -> index)
    /// ```
    public init(siblings: [TreeChange]) {
        self.init()
        for change in siblings {
            switch change.kind {
            case .delete:
                deletions.append(change.index)
            case .insert:
                insertions.append(change.index)
            case .update:
                updates.append(change.index)
            case .unchanged:
                break
            }
            if let from = change.movedFrom {
                moves.append((from: from, to: change.index))
            }
        }
    }

    /// `true` when there is nothing to apply.
    public var isEmpty: Bool {
        updates.isEmpty && insertions.isEmpty && deletions.isEmpty && moves.isEmpty
    }

    /// The deletions as an index set (OLD indexes).
    public var deletionIndexes: IndexSet {
        IndexSet(deletions)
    }

    /// The insertions as an index set (NEW indexes).
    public var insertionIndexes: IndexSet {
        IndexSet(insertions)
    }

    /// The updates as an index set (NEW indexes).
    public var updateIndexes: IndexSet {
        IndexSet(updates)
    }
}

extension Array where Element: Diffable {
    /// Diffs this list against `new` and returns the result as `ListChanges`.
    public func listChanges(to new: [Element], algorithm: DiffAlgorithm = .heckel) -> ListChanges {
        let changes: (updates: [Int], insertions: [Int], deletions: [Int], moves: [(Int, Int)]) = diff(
            new,
            algorithm: algorithm
        )
        return ListChanges(changes)
    }
}
