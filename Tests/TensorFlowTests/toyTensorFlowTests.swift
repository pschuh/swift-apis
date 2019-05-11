import XCTest
@testable import toyTensorFlow

final class toyTensorFlowTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(toyTensorFlow().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
