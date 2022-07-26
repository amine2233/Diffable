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

extension Array where Element: DiffableTree {
    var countChildren: Int {
        reduce(count) { partialResult, element in
            return partialResult + element.children.count
        }
    }
}
