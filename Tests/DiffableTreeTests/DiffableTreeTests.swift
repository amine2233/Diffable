//
//  File.swift
//  
//
//  Created by work on 13/07/2022.
//

import XCTest
import Diffable
@testable import DiffableTree

final class DiffableTreeTests: XCTestCase {

    func test_update_parent() throws {
        // Given
        let file = Node("hello.pgp")
        let file2 = Node("hello_2.pgp")

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.operation == .updated(parent: nil, newValue: file2, at: 0))
        XCTAssert(operation.children.isEmpty == true)
    }

    func test_insert_children() throws {
        // Given
        let file = Node("hello.pgp")
        let file2 = Node("hello.pgp") {
            Node("world_1.pgp")
            Node("world_2.pgp")
        }

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.operation == .unchanged(parent: nil, at: 0))
        XCTAssert(operation.children == [
            DiffableTreeNode<Node<String>>.init(value: Node("world_1.pgp"), operation: .inserted(parent: file, at: 0), children: []),
            DiffableTreeNode<Node<String>>.init(value: Node("world_2.pgp"), operation: .inserted(parent: file, at: 1), children: [])
        ])
    }

    func test_remove_children() throws {
        // Given
        let file = Node("hello.pgp") {
            Node("world_1.pgp")
            Node("world_2.pgp")
        }
        let file2 = Node("hello.pgp")

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.operation == .unchanged(parent: nil, at: 0))
        XCTAssert(operation.children == [
            DiffableTreeNode<Node<String>>.init(value: Node("world_1.pgp"), operation: .deleted(parent: file, at: 0), children: []),
            DiffableTreeNode<Node<String>>.init(value: Node("world_2.pgp"), operation: .deleted(parent: file, at: 1), children: [])
        ])
    }

    func test_add_element_in_child_of_root() throws {
        // Given
        let file = Node("hello.pgp") {
            Node("world.pgp")
        }
        let file2 = Node("hello.pgp") {
            Node("world.pgp") {
                Node("under_world.pgp")
            }
        }

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.operation == .unchanged(parent: nil, at: 0))
        XCTAssert(operation.children == [
            DiffableTreeNode<Node<String>>.init(value: Node("world.pgp"), operation: .unchanged(parent: file, at: 1), children: [
                DiffableTreeNode<Node<String>>.init(value: Node("under_world.pgp"), operation: .inserted(parent: Node("world.pgp"), at: 0), children: []),
            ]),
        ])
    }

    func test_complex_example() throws {
        // Given
        let file = Node("hello.pgp") {
            Node("world.pgp")
            Node("world_1.pgp") {
                Node("under_world_1.pgp")
            }
        }
        let file2 = Node("hello_new.pgp") {
            Node("world*.pgp") {
                Node("under_world*.pgp")
            }
            Node("world_1.pgp")
            Node("world_2.pgp")
        }

        // When
        let operation = file.diff(file2)

        // Then
        let expected = [
            DiffableTreeNode<Node<String>>.init(value: Node("world.pgp"), operation: .updated(parent: file, newValue: Node("world*.pgp") {
                Node("under_world*.pgp")
            }, at: 1), children: [
                DiffableTreeNode<Node<String>>.init(value: Node("under_world*.pgp"), operation: .inserted(parent: Node("world.pgp"), at: 0), children: [])
            ]),
            DiffableTreeNode<Node<String>>.init(value: Node("world_1.pgp") { Node("under_world_1.pgp") }, operation: .unchanged(parent: file, at: 1), children: [
                DiffableTreeNode<Node<String>>(value: Node("under_world_1.pgp"), operation: .deleted(parent: Node("world_1.pgp") {
                    Node("under_world_1.pgp")
                }, at: 0), children: [])
            ]),
            DiffableTreeNode<Node<String>>.init(value: Node("world_2.pgp"), operation: .inserted(parent: file, at: 2), children: [])
        ]
        XCTAssert(operation.operation == .updated(parent: nil, newValue: file2, at: 0))
        XCTAssert(operation.children == expected)
    }

    func test_is_empty_when_do_not_have_a_change() throws {
        // Given
        let file = Node("hello.pgp")
        let file2 = Node("hello.pgp")

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.isEmpty == true)
    }

    func test_is_empty_when_have_a_change() throws {
        // Given
        let file = Node("hello.pgp")
        let file2 = Node("hello2.pgp")

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.isEmpty == false)
    }

    func test_is_empty_when_do_not_have_change_on_children() throws {
        // Given
        let file = Node("hello.pgp") {
            Node("world.pgp")
        }
        let file2 = Node("hello.pgp") {
            Node("world.pgp")
        }

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.isEmpty == true)
    }

    func test_is_empty_when_we_have_a_change_with_children() throws {
        // Given
        let file = Node("hello.pgp") {
            Node("world.pgp")
        }
        let file2 = Node("hello.pgp") {
            Node("world2.pgp")
        }

        // When
        let operation = file.diff(file2)

        // Then
        XCTAssert(operation.isEmpty == false)
    }

    func test_first_item() throws {
        // Given
        let expectedNode = Node("world_1.pgp") {
            Node("under_world_1.pgp")
        }
        let file = Node("hello.pgp") {
            Node("world.pgp")
            expectedNode
        }

        // When
        let item = file.parent(whereChild: { $0.value == Node("under_world_1.pgp").value })

        // Then
        XCTAssert(item == expectedNode)
    }
}
