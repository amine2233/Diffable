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
public struct ListChanges {
    public var updates: [Int]
    public var insertions: [Int]
    public var deletions: [Int]
    public var moves: [(from: Int, to: Int)]

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

    public var isEmpty: Bool {
        updates.isEmpty && insertions.isEmpty && deletions.isEmpty && moves.isEmpty
    }

    public var deletionIndexes: IndexSet {
        IndexSet(deletions)
    }

    public var insertionIndexes: IndexSet {
        IndexSet(insertions)
    }

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
