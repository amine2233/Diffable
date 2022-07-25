//
//  File.swift
//  
//
//  Created by work on 13/07/2022.
//

import Foundation

public enum DiffableTreeOperation<T: DiffableTree, Index>: Equatable, CustomStringConvertible where Index: Equatable {
    case unchanged(parent: T?, at: Index)
    case inserted(parent: T?, at: Index)
    case deleted(parent: T?, at: Index)
    case updated(parent: T?, newValue: T, at: Index)

    public var description: String {
        switch self {
            case .unchanged(_, let at):
                return String("NOP at \(at)")
            case .inserted(_, let at):
                return String("I at \(at)")
            case .deleted(_, let at):
                return String("D at \(at)")
            case .updated(_, let newValue, let at):
                return String("U(\(newValue.value) at \(at)")
        }
    }
}

public struct DiffableTreeNode<T: DiffableTree>: Equatable {
    var value: T
    var operation: DiffableTreeOperation<T, T.Children.Index>
    var children: [DiffableTreeNode<T>]

    init(value: T, operation: DiffableTreeOperation<T, T.Children.Index>, children: [DiffableTreeNode<T>]) {
        self.value = value
        self.operation = operation
        self.children = children
    }

    public var description: String {
        var message = ""
        message += "\(value)\n"
        message += "operation: \(operation)\n"
        message += "\t\(children.map { $0.description + "\n" }.joined(separator: "\n"))"
        return message
    }
}

extension DiffableTree {

    public func diff(_ tree: Self, parent: Self? = nil, level: Int = 0) -> DiffableTreeNode<Self> where Self == Self.Children.Element {

        var operation: DiffableTreeNode<Self> = .init(value: self, operation: .unchanged(parent: parent, at: level), children: [])

        if value != tree.value {
            operation.operation = .updated(parent: parent, newValue: tree, at: level)
        }

        if !children.isEmpty {
            var childrenOperations: [DiffableTreeNode<Self>] = []

            let count = max(children.endIndex, tree.children.endIndex)

            for i in 0...count {
                if children.element(safeIndex: i) == nil && tree.children.element(safeIndex: i) != nil {
                    childrenOperations.append(.init(value: tree.children.element(safeIndex: i)!, operation: .inserted(parent: self, at: i), children: []))
                } else if children.element(safeIndex: i) != nil && tree.children.element(safeIndex: i) == nil {
                    childrenOperations.append(.init(value: children.element(safeIndex: i)!, operation: .deleted(parent: self, at: i), children: []))
                } else if children.element(safeIndex: i) != nil && tree.children.element(safeIndex: i) != nil {
                    childrenOperations.append(children[i].diff(tree.children[i], parent: self, level: level + 1))
                }
            }

            operation.children.append(contentsOf: childrenOperations)

        } else {
            if !tree.children.isEmpty {
                operation.children = tree.children.enumerated().map { .init(value: $1 , operation: .inserted(parent: self, at: $0), children: []) }
            }
        }

        return operation
    }
}

extension Array where Element: DiffableArrayTree {

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

extension Collection where Index == Int {
    public func element(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}

public struct DiffState {
    public var updates: [IndexPath]
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
