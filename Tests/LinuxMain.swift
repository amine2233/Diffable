import XCTest
import DiffableTests
import SwiftTestReporter

_ = TestObserver()
var tests = [XCTestCaseEntry]()
tests += DiffableTests.allTests()
XCTMain(tests)

