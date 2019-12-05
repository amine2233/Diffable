//
//  Array+Diff.swift
//  Diffable
//
//  Created by Amine Bensalah on 05/12/2019.
//

import Foundation

extension Array where Element: Diffable {

    /// Calculate the changes between self and the `new` array.
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    /// - Returns: A tuple containing the changes.
    public func diff(_ new: [Element]) -> (updates: [Index], insertions: [Index], deletions: [Index], moves: [(Index, Index)]) {

        let diff = Diff()

        let result = diff.process(old: self, new: new)

        var deletions: [Index] = []
        var insertions: [Index] = []
        var updates: [Index] = []
        var moves: [(from: Index, to: Index)] = []

        for step in result {
            switch step {
            case .delete(let index, _):
                deletions.append(index)
            case .insert(let index, _):
                insertions.append(index)
            case .update(let index, _):
                updates.append(index)
            case let .move(from, to, _):
                moves.append((from: from, to: to))
            }
        }

        return (updates, insertions, deletions, moves)
    }
}
