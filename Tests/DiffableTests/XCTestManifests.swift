import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(DiffableTests.allTests)
    ]
}
#endif
