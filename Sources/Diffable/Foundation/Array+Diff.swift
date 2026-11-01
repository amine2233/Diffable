import Foundation

extension Array where Element: Diffable {
    /// Calculate the changes between current and the `new` array, with Heckel's algorithm.
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    /// - Returns: A tuple containing the changes. See `diff(_:algorithm:)`.
    public func diff(_ new: [Element])
        -> (updates: [Index], insertions: [Index], deletions: [Index], moves: [(
            Index,
            Index
        )]) {
        diff(new, algorithm: .heckel)
    }

    /// Calculate the changes between current and the `new` array.
    ///
    /// ```
    ///  old: [ A  B  C ]                    new: [ B  C  D' ]       (D' = D edited)
    ///         0  1  2                             0  1  2
    ///
    ///  deletions  -> [0]                   index in OLD   (A is gone)
    ///  insertions -> [2]                   index in NEW   (D' is new)
    ///  updates    -> []                    index in NEW   (kept item whose content changed)
    ///  moves      -> []                    (from OLD, to NEW)   Heckel only
    /// ```
    ///
    /// Index spaces differ by design: deletions refer to the old array, everything else to the new one,
    /// which matches the order UIKit expects (apply deletions, then insertions/moves, then reload updates).
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    ///   - algorithm: `.heckel` (moves, linear) or `.myers` (shortest script, no moves)
    /// - Returns: A tuple containing the changes.
    public func diff(
        _ new: [Element],
        algorithm: DiffAlgorithm
    ) -> (updates: [Index], insertions: [Index], deletions: [Index], moves: [(
        Index,
        Index
    )]) {
        let result = algorithm.process(old: self, new: new)

        var deletions: [Index] = []
        var insertions: [Index] = []
        var updates: [Index] = []
        var moves: [(from: Index, to: Index)] = []

        for step in result {
            switch step {
            case let .delete(index, _):
                deletions.append(index)
            case let .insert(index, _):
                insertions.append(index)
            case let .update(index, _):
                updates.append(index)
            case let .move(from, to, _):
                moves.append((from: from, to: to))
            }
        }

        return (updates, insertions, deletions, moves)
    }
}
