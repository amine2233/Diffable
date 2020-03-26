//
//  Array+UIDiff.swift
//  Diffable
//
//  Created by Amine Bensalah on 05/12/2019.
//


#if os(OSX)
import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
extension Array where Element: Diffable {

    /// Calculate the changes between current and the `new` array.
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    ///   - section: The section in which this diff should be applied to, this is used to create indexPath's. Default is 0
    /// - Returns: A tuple containing the changes.
    public func diff(_ new: [Element], forSection section: Int = 0) -> (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)]) {

        let diff = Diff()

        let result = diff.process(old: self, new: new)

        var deletions = [IndexPath]()
        var insertions = [IndexPath]()
        var updates = [IndexPath]()
        var moves = [(from: IndexPath, to: IndexPath)]()

        for step in result {
            switch step {

            case .delete(let index, _):
                deletions.append(IndexPath(item: index, section: section))
            case .insert(let index, _):
                insertions.append(IndexPath(item: index, section: section))
            case .update(let index, _):
                updates.append(IndexPath(item: index, section: section))
            case let .move(from, to, _):
                moves.append((from: IndexPath(item: from, section: section), to: IndexPath(item: to, section: section)))
            }
        }

        return (updates, insertions, deletions, moves)
    }
}
#endif
