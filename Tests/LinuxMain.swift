import XCTest
import DiffableTests
import SwiftTestReporter

var tests = [XCTestCaseEntry]()
tests += DiffableTests.allTests()
XCTMain(tests)

_ = TestObserver()
