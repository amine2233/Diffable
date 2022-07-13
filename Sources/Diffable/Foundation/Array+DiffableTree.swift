//
//  File.swift
//  
//
//  Created by work on 13/07/2022.
//

import Foundation

extension Array where Element: DiffableTree {

    /// Calculate the changes between current and the `new` array.
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    /// - Returns: A tuple containing the changes.
    public func diffTree(_ new: [Element], level: Index = 0) -> DiffState {
        let diff = Diff()

        let result = diff.process(old: self, new: new)

        var deletions: [IndexPath] = []
        var insertions: [IndexPath] = []
        var updates: [IndexPath] = []
        var moves: [(from: IndexPath, to: IndexPath)] = []

        var diffState = DiffState(updates: updates, insertions: insertions, deletions: deletions, moves: moves)

        func process(_ source: [IndexPath], initial: Self, new: Self, at index: Index) {
            if !source.isEmpty {
                let children = initial[safeIndex: index]?.children ?? []
                let newChildren = new[safeIndex: index]?.children ?? []
                let resultRecursion = children.diffTree(newChildren, level: level + 1)
                diffState.merge(resultRecursion)
            }
        }

        for step in result {
            switch step {
            case .delete(let index, _):
                deletions.append(IndexPath(item: index, section: level))
                diffState.appendDeletions(deletions)
                process(deletions, initial: self, new: new, at: index)
            case .insert(let index, _):
                insertions.append(IndexPath(item: index, section: level))
                diffState.appendInsertions(insertions)
                process(insertions, initial: self, new: new, at: index)
            case .update(let index, _):
                updates.append(IndexPath(item: index, section: level))
                diffState.appendUpdates(updates)
                process(updates, initial: self, new: new, at: index)
            case let .move(from, to, _):
                moves.append((from: IndexPath(item: from, section: level), to: IndexPath(item: to, section: level)))
                diffState.appendMoves(moves)
                process(moves.map { $0.from }, initial: self, new: new, at: from)
                process(moves.map { $0.to }, initial: self, new: new, at: to)
            }
        }

        return diffState
    }
}


extension Array {
    public subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}

public struct DiffState {
    public var updates: IndexSet
    public var insertions: [IndexPath]
    public var deletions: [IndexPath]
    public var moves: [(IndexPath, IndexPath)]

    init(updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)]) {
        self.updates = updates
        self.insertions = insertions
        self.deletions = deletions
        self.moves = moves
    }

    var isEmpty: Bool {
        updates.isEmpty && insertions.isEmpty && deletions.isEmpty && moves.isEmpty
    }

    mutating func merge(_ diffState: DiffState) {
        updates.append(contentsOf: diffState.updates)
        insertions.append(contentsOf: diffState.insertions)
        deletions.append(contentsOf: diffState.deletions)
        moves.append(contentsOf: diffState.moves)
    }

    mutating func appendUpdates(_ element: [IndexPath]) {
        updates.append(contentsOf: element)
    }

    mutating func appendInsertions(_ element: [IndexPath]) {
        insertions.append(contentsOf: element)
    }

    mutating func appendDeletions(_ element: [IndexPath]) {
        deletions.append(contentsOf: element)
    }

    mutating func appendMoves(_ element: [(IndexPath, IndexPath)]) {
        moves.append(contentsOf: element)
    }
}
