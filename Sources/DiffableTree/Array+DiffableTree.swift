import Foundation

extension Collection where Element: DiffableTree, Index == Int {

    /// Calculate the changes between current and the `new` array.
    ///
    /// - Parameters:
    ///   - new: a collection to compare the calee to
    /// - Returns: A tuple containing the changes.
    public func diffTree(_ new: Self, parent: Element? = nil, level: Index = 0) -> [DiffableTreeNode<Element>] where Self.Element.Children.Element == Self.Element {

        var operation: [DiffableTreeNode<Element>] = []

        let diffCount = Swift.max(self.count, new.count)

        for i in 0...diffCount {
            if self[safeIndex: i] == nil && new[safeIndex: i] != nil {
                operation.append(.init(value: new[safeIndex: i]!, operation: .inserted(parent: parent, at: i), children: []))
            } else if self[safeIndex: i] != nil && new[safeIndex: i] == nil {
                operation.append(.init(value: self[safeIndex: i]!, operation: .deleted(parent: parent, at: i), children: []))
            } else if self[safeIndex: i] != nil && new[safeIndex: i] != nil {
                operation.append(self[i].diff(new[i], parent: parent, level: level+1))
            }
        }

        return operation
    }
}

extension Collection where Element: DiffableTreeNodeProtocol {

    public var isEmptyOperation: Bool {
        reduce(true) { partialResult, elements in
            partialResult && elements.isEmpty
        }
    }
}
