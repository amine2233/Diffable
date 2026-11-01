//
//  Array+UIDiff.swift
//  DiffableUI
//
//  Created by Amine Bensalah on 05/12/2019.
//


#if SWIFT_PACKAGE
import Diffable
#endif

#if os(OSX)
import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

#if !os(Linux)
extension Array where Element: Diffable {

    /// Calculate the changes between current and the `new` array as `IndexPath`s.
    ///
    /// ```
    ///  section 1
    ///  [ A  B  C ]  ->  [ B  C  D ]        deletions  [1,0]
    ///                                       insertions [1,2]
    /// ```
    ///
    /// Same index spaces as `diff(_:algorithm:)`: deletions use the old array, the rest the new one.
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    ///   - section: The section in which this diff should be applied to, this is used to create indexPath's. Default is 0
    ///   - algorithm: `.heckel` (default) or `.myers`
    /// - Returns: A tuple containing the changes.
    public func diff(_ new: [Element], forSection section: Int = 0, algorithm: DiffAlgorithm = .heckel) -> (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)]) {

        let changes: (updates: [Int], insertions: [Int], deletions: [Int], moves: [(Int, Int)]) = diff(new, algorithm: algorithm)

        func indexPath(_ item: Int) -> IndexPath {
            return IndexPath(item: item, section: section)
        }

        let updates = changes.updates.map(indexPath)
        let insertions = changes.insertions.map(indexPath)
        let deletions = changes.deletions.map(indexPath)
        let moves = changes.moves.map { (from: indexPath($0.0), to: indexPath($0.1)) }

        return (updates, insertions, deletions, moves)
    }
}
#endif
