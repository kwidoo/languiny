import XCTest
@testable import EngineBridge

final class EngineBridgeTests: XCTestCase {
    func testRemapWord() {
        let result = remapWord("ghbdtn", from: 0, to: 1)
        XCTAssertEqual(result, "привет")
    }

    func testShouldSwitch() {
        XCTAssertTrue(shouldSwitch("ghbdtn", current: 0))
    }
}
