import Foundation
import Diffable

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

    public var value: T
    public var operation: DiffableTreeOperation<T, T.Children.Index>
    public var children: [DiffableTreeNode<T>]

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
                if children[safeIndex: i] == nil && tree.children[safeIndex: i] != nil {
                    childrenOperations.append(.init(value: tree.children[safeIndex: i]!, operation: .inserted(parent: self, at: i), children: []))
                } else if children[safeIndex: i] != nil && tree.children[safeIndex: i] == nil {
                    childrenOperations.append(.init(value: children[safeIndex: i]!, operation: .deleted(parent: self, at: i), children: []))
                } else if children[safeIndex: i] != nil && tree.children[safeIndex: i] != nil {
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

extension Collection where Index == Int {
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
