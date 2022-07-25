//
//  Diffable.swift
//  Diffable
//
//  Created by Amine Bensalah on 05/12/2019.
//

import Foundation

public protocol Diffable: Hashable {
    var primaryKeyValue: String { get }
}

public protocol DiffableTree: Diffable {
    associatedtype Value: Hashable
    associatedtype Children: Collection where
    Children.Element: DiffableTree,
    Children.Element.Children == Children,
    Children.Index == Int

    var value: Value { get }
    var children: Children { get }
}

public protocol DiffableArrayTree: Diffable {
    associatedtype DiffableItem: DiffableArrayTree

    var children: [DiffableItem] { get }
}

extension Array where Element: DiffableArrayTree {
    var countChildren: Int {
        reduce(count) { partialResult, child in
            return partialResult + child.children.countChildren
        }
    }
}
