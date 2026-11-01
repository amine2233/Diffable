import Foundation

extension RandomAccessCollection where Element: Diffable {
    /// Calculate the changes between this collection and `new`, with Heckel's algorithm.
    ///
    /// Works on any random-access collection of `Diffable` elements, not only `Array`: `ArraySlice`,
    /// `ContiguousArray`, a `Range`, or your own collection type. The two collections may even be of
    /// different types.
    ///
    /// ```swift
    /// let old = ContiguousArray(products)
    /// let new = products[2...]                 // an ArraySlice
    /// let changes = old.diff(new)
    /// ```
    ///
    /// - Parameter new: The collection to compare to.
    /// - Returns: The same tuple as `Array.diff(_:)`. All indexes are **offsets from the start** of their
    ///   collection (0 for the first element), also for a slice whose `startIndex` is not 0.
    public func diff<New: RandomAccessCollection>(
        _ new: New
    ) -> (updates: [Int], insertions: [Int], deletions: [Int], moves: [(Int, Int)])
        where New.Element == Element {
        diff(new, algorithm: .heckel)
    }

    /// Calculate the changes between this collection and `new` with the chosen algorithm.
    ///
    /// ```
    ///  old: ArraySlice [ B  C  D ]   (startIndex 1)      new: ContiguousArray [ C  D  E ]
    ///                    0  1  2     offsets, not indexes             0  1  2
    ///
    ///  deletions  -> [0]      B is gone                  insertions -> [2]      E is new
    /// ```
    ///
    /// The elements are copied into arrays first, which costs O(n), the same order as the diff itself.
    ///
    /// - Parameters:
    ///   - new: The collection to compare to.
    ///   - algorithm: `.heckel` (moves, linear) or `.myers` (shortest script, no moves).
    /// - Returns: The same tuple as `Array.diff(_:algorithm:)`, with offsets as indexes.
    public func diff<New: RandomAccessCollection>(
        _ new: New,
        algorithm: DiffAlgorithm
    ) -> (updates: [Int], insertions: [Int], deletions: [Int], moves: [(Int, Int)])
        where New.Element == Element {
        Array(self).changes(to: Array(new), algorithm: algorithm)
    }
}
