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

    func testExample() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1), AnyDiffable(2)]

        let value = actualArray.diff(newArray)

        print(value)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
