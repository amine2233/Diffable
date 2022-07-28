import Foundation
import Diffable

public protocol DiffableTree: Diffable {
    associatedtype Value: Hashable
    associatedtype Children: Collection where
    Children.Element: DiffableTree,
    Children.Element.Children == Children,
    Children.Index == Int

    var value: Value { get }
    var children: Children { get }
}

extension Collection where Element: DiffableTree {

    public var countChildren: Int {
        reduce(count) { partialResult, element in
            return partialResult + element.countChildren
        }
    }

    public func parent(whereChild predicate: (Element) -> Bool, parent: ItemPosition<Element> = .root) -> Element? where Element.Children.Element == Element {
        var element: Element?
        for _element in self {
            guard let _element = _element.parent(whereChild: predicate, parent: parent) else { continue }
            element = _element
            break
        }
        return element
    }
}

extension DiffableTree {

    public subscript(childAt index: Int) -> Children.Element? {
        guard index >= 0, index < children.endIndex else {
            return nil
        }
        return children[index]
    }

    public var countChildren: Int {
        children.count
    }

    public func parent(whereChild predicate: (Self) -> Bool, parent: ItemPosition<Self> = .root) -> Self? where Self.Children.Element == Self {
        if predicate(self) {
            switch parent {
                case .root: return nil
                case .item(let node): return node
            }
        } else {
            return children.parent(whereChild: predicate, parent: .item(self))
        }
    }
}

public enum ItemPosition<T: DiffableTree>: Equatable {
    case root
    case item(T)
}
