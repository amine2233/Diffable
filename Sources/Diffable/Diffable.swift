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
    associatedtype DiffableItem: DiffableTree

    var children: [DiffableItem] { get }
}

extension Array where Element: DiffableTree {
    var countChildren: Int {
        reduce(count) { partialResult, child in
            return partialResult + child.children.countChildren
        }
    }
}
