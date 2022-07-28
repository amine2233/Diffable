import Foundation
import Diffable

public enum DiffableTreeOperation<T: DiffableTree, Index>: Equatable, CustomStringConvertible where Index: Equatable {

    case unchanged(parent: T?)
    case inserted(parent: T?, at: Index)
    case deleted(parent: T?, at: Index)
    case updated(parent: T?, newValue: T)

    public var description: String {
        switch self {
            case .unchanged(_):
                return String("NOP")
            case .inserted(_, let at):
                return String("I at \(at)")
            case .deleted(_, let at):
                return String("D at \(at)")
            case .updated(_, let newValue):
                return String("U(\(newValue.value)")
        }
    }

    public var isEmpty: Bool {
        switch self {
            case .unchanged(_): return true
            case .inserted(_, _), .deleted( _, _), .updated(_, _): return false
        }
    }
}

public protocol DiffableTreeNodeProtocol: Equatable {
    associatedtype Item: DiffableTree

    var value: Item { get }
    var operation: DiffableTreeOperation<Item, Item.Children.Index> { get }
    var children: [DiffableTreeNode<Item>] { get }

    var isEmpty: Bool { get }
}

extension DiffableTreeNodeProtocol {

    public var isEmpty: Bool {
        operation.isEmpty && children.isEmptyOperation
    }
}

public struct DiffableTreeNode<T: DiffableTree>: DiffableTreeNodeProtocol {

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

        var operation: DiffableTreeNode<Self> = .init(value: self, operation: .unchanged(parent: parent), children: [])

        if !children.isEmpty {
            if tree.children.isEmpty {
                operation.children.append(contentsOf: children.enumerated().map { DiffableTreeNode<Self>(value: $1, operation: .deleted(parent: self, at: $0), children: []) })
            } else {
                operation.children.append(contentsOf: children.diffTree(tree.children, parent: self, level: level + 1))
            }
        } else {
            if !tree.children.isEmpty {
                operation.children = tree.children.enumerated().map { .init(value: $1 , operation: .inserted(parent: self, at: $0), children: []) }
            }
        }

        if value != tree.value || !operation.children.isEmpty {
            operation.operation = .updated(parent: parent, newValue: tree)
        }

        return operation
    }
}

extension Collection where Index == Int {
    public subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
