#if os(Linux)
import XCTest
import SwiftTestReporter
import DiffableTests

_ = TestObserver()

var tests = [XCTestCaseEntry]()
tests += DiffableTests.allTests()
XCTMain(tests)

#endif
