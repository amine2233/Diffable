//
//  File.swift
//  
//
//  Created by work on 25/07/2022.
//

import Foundation
import DiffableTree

@resultBuilder
struct NodeBuilder {
    static func buildBlock<Value>(_ children: Node<Value>...) -> [Node<Value>] {
        children
    }
}

struct Node<Value: Hashable>: DiffableTree , Hashable {
    public var primaryKeyValue: String {
        return "\(value.hashValue)"
    }

    var value: Value
    var children: [Node<Value>]

    init(_ value: Value, children: [Node<Value>] = []) {
        self.value = value
        self.children = children
    }

    init(_ value: Value, @NodeBuilder builder: () -> [Node]) {
        self.value = value
        self.children = builder()
    }

    mutating func add(element: Node) {
        children.append(element)
    }

    mutating func delete(element: Node<Value>) {
        children = children.filter { $0 != element }
    }
}
