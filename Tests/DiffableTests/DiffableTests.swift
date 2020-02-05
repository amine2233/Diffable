//
//  DiffableTests.swift
//  Diffable Tests
//
//  Created by Amine Bensalah on 05/12/2019.
//

import XCTest
@testable import Diffable

extension Int: Diffable {
    public var primaryKeyValue: String {
        return "\(self)"
    }
}

class DiffableTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNewEntryDifference() {
        let actualArray: [AnyDiffable] = []
        let newArray = [AnyDiffable(1)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 1)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testNoDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1), AnyDiffable(2)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 0)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testAddNewElementDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(2)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 1)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testRemoveNewElementDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 0)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 1)
    }

    func testMoveElementDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(2), AnyDiffable(1)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 0)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 2)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testUpdateElementDifference() {

        struct Car: Diffable {
            var id: String
            var name: String

            var primaryKeyValue: String {
                return self.id
            }
        }

        let actualArray = [AnyDiffable(Car(id: "1", name: "Audi")), AnyDiffable(Car(id: "2", name: "BMW"))]
        let newArray = [AnyDiffable(Car(id: "1", name: "Audi")), AnyDiffable(Car(id: "2", name: "Mercedes"))]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 0)
        XCTAssertEqual(value.updates.count, 1)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testManyEntryDifference() {
        let actualArray: [AnyDiffable] = []
        let newArray = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(3)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 3)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testManyEntriesDifference() {
        let actualArray: [AnyDiffable] = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(3), AnyDiffable(6)]
        let newArray = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(3), AnyDiffable(4), AnyDiffable(5), AnyDiffable(6)]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 2)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 0)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testManyMoveElementsDifference() {

        struct Car: Diffable {
            var id: String
            var name: String

            var primaryKeyValue: String {
                return self.id
            }
        }

        let actualArray = [Car(id: "1", name: "Audi"), Car(id: "2", name: "BMW"), Car(id: "3", name: "Mercedes")]
        let newArray = [Car(id: "2", name: "BMW"), Car(id: "3", name: "Mercedes"), Car(id: "1", name: "Audi")]

        let value = actualArray.diff(newArray)

        XCTAssertEqual(value.insertions.count, 0)
        XCTAssertEqual(value.updates.count, 0)
        XCTAssertEqual(value.moves.count, 3)
        XCTAssertEqual(value.deletions.count, 0)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    static var allTests = [
        ("testNewEntryDifference",testNewEntryDifference),
        ("testNoDifference",testNoDifference),
        ("testAddNewElementDifference",testAddNewElementDifference),
        ("testRemoveNewElementDifference",testRemoveNewElementDifference),
        ("testMoveElementDifference",testMoveElementDifference),
        ("testUpdateElementDifference",testUpdateElementDifference),
        ("testManyEntryDifference",testManyEntryDifference),
        ("testManyEntriesDifference",testManyEntriesDifference),
        ("testManyMoveElementsDifference",testManyMoveElementsDifference)
    ]
}
