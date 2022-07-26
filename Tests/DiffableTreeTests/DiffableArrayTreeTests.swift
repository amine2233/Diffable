//
//  DiffableArrayTreeTests.swift
//  
//
//  Created by work on 25/07/2022.
//

import XCTest
@testable import DiffableTree

class DiffableArrayTreeTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_insert_without_children() {
        // Given
        let file = Node("hello.pgp")
        let file2 = Node("hello_2.pgp")

        // When
        let operation = [file].diffTree([file2]).first!

        // Then
        XCTAssert(operation.operation == .updated(parent: nil, newValue: file2, at: 0))
        XCTAssert(operation.children.isEmpty == true)
    }

//    func test_insert_with_children() {
//        var file = File(name: "hello.pgp")
//        let newFile = File(name: "world.pgp")
//        file.add(element: newFile)
//
//        let actualArray: [File] = []
//        let newArray: [File] = [file]
//
//        let value = actualArray.diffTree(newArray)
//
//        XCTAssertEqual(value.insertions, [IndexPath(item: 0, section: 0), IndexPath(item: 0, section: 1)])
//        XCTAssertTrue(value.updates.isEmpty)
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertTrue(value.deletions.isEmpty)
//    }
//
//    func test_insert_with_childrens() {
//        var file = File(name: "hello.pgp")
//        let newFile = File(name: "world.pgp")
//        let newFile2 = File(name: "world2.pgp")
//        file.add(element: newFile)
//        file.add(element: newFile2)
//
//        let actualArray: [File] = []
//        let newArray: [File] = [file]
//
//        let value = actualArray.diffTree(newArray)
//
////        XCTAssertEqual(value.insertions, [IndexPath(item: 0, section: 0), IndexPath(item: 0, section: 1), IndexPath(item: 1, section: 1)])
//        XCTAssertTrue(value.updates.isEmpty)
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertTrue(value.deletions.isEmpty)
//    }
//
//    func test_insert_with_children_has_children() {
//        var file = File(name: "hello.pgp")
//        var newFile = File(name: "world.pgp")
//        let otherFile = File(name: "world.pgp")
//        newFile.add(element: otherFile)
//        file.add(element: newFile)
//
//        let actualArray: [File] = []
//        let newArray: [File] = [file]
//
//        let value = actualArray.diffTree(newArray)
//
//        XCTAssertEqual(value.insertions, [IndexPath(item: 0, section: 0), IndexPath(item: 0, section: 1), IndexPath(item: 0, section: 2)])
//        XCTAssertTrue(value.updates.isEmpty)
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertTrue(value.deletions.isEmpty)
//    }
//
//    func test_update_parent_using_insertion_children() {
//        var file = File(name: "hello.pgp")
//        let newFile = File(name: "world.pgp")
//
//        let actualArray: [File] = [file]
//        file.add(element: newFile)
//        let newArray: [File] = [file]
//
//        let value = actualArray.diffTree(newArray)
//
//        XCTAssertEqual(value.insertions, [IndexPath(item: 0, section: 1)])
//        XCTAssertEqual(value.updates, [IndexPath(item: 0, section: 0)])
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertTrue(value.deletions.isEmpty)
//    }
//
//    func test_update_parent_using_insertion_in_children_of_children() {
//        var file = File(name: "hello.pgp")
//        let newFile = File(name: "world.pgp")
//        file.add(element: newFile)
//
//        let actualArray: [File] = [file]
//
//        var file2 = File(name: "hello.pgp")
//        var newFile2 = File(name: "world.pgp")
//        let otherFile = File(name: "world2.pgp")
//        newFile2.add(element: otherFile)
//        file2.add(element: newFile2)
//
//        let newArray: [File] = [file2]
//
//        let value = actualArray.diffTree(newArray)
//        XCTAssertEqual(value.insertions, [IndexPath(item: 0, section: 2)])
//        XCTAssertEqual(value.updates, [IndexPath(item: 0, section: 0), IndexPath(item: 0, section: 1)])
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertTrue(value.deletions.isEmpty)
//    }
//
//    func test_update_parent_using_removing_children() {
//        var file = File(name: "hello.pgp")
//        let newFile = File(name: "world.pgp")
//        file.add(element: newFile)
//
//        let actualArray: [File] = [file]
//        file.delete(element: newFile)
//        let newArray: [File] = [file]
//
//        let value = actualArray.diffTree(newArray)
//
//        XCTAssertTrue(value.insertions.isEmpty)
//        XCTAssertEqual(value.updates, [IndexPath(item: 0, section: 0)])
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertEqual(value.deletions, [IndexPath(item: 0, section: 1)])
//    }
//
//    func test_update_parent_using_removing_children_of_children() {
//        var file = File(name: "hello.pgp")
//        var newFile = File(name: "world.pgp")
//        let otherFile = File(name: "world2.pgp")
//        newFile.add(element: otherFile)
//        file.add(element: newFile)
//
//        let actualArray: [File] = [file]
//
//        var file2 = File(name: "hello.pgp")
//        let newFile2 = File(name: "world.pgp")
//        file2.add(element: newFile2)
//
//        let newArray: [File] = [file2]
//
//        let value = actualArray.diffTree(newArray)
//
//        XCTAssertTrue(value.insertions.isEmpty)
//        XCTAssertEqual(value.updates, [IndexPath(item: 0, section: 0), IndexPath(item: 0, section: 1)])
//        XCTAssertTrue(value.moves.isEmpty)
//        XCTAssertEqual(value.deletions, [IndexPath(item: 0, section: 2)])
//    }
}
