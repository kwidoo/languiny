import XCTest
@testable import Languiny
import ApplicationServices

final class WordBufferTests: XCTestCase {
    private func makeEvent(char: Character, pid: Int32 = 1, keyCode: CGKeyCode = 0) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)!
        var utf16 = Array(String(char).utf16)
        event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        event.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(pid))
        return event
    }

    private func makeArrowEvent(pid: Int32 = 1, keyCode: CGKeyCode = 123) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)!
        event.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(pid))
        return event
    }

    private func makeBackspaceEvent(pid: Int32 = 1) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)!
        event.setIntegerValueField(.eventSourceUnixProcessID, value: Int64(pid))
        return event
    }

    func testWordBoundaries() {
        let tap = InputTap()
        var results: [(String, Character?)] = []
        tap.onWordBoundary = { word, sep in results.append((word, sep)) }

        for c in "test" { _ = tap.handleEvent(makeEvent(char: c), type: .keyDown) }
        _ = tap.handleEvent(makeEvent(char: " ", keyCode: 49), type: .keyDown)
        for c in "next" { _ = tap.handleEvent(makeEvent(char: c), type: .keyDown) }
        _ = tap.handleEvent(makeArrowEvent(), type: .keyDown)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].0, "test")
        XCTAssertEqual(results[0].1, " ")
        XCTAssertEqual(results[1].0, "next")
        XCTAssertNil(results[1].1)
    }

    func testBackspaceUpdatesBuffer() {
        let tap = InputTap()
        var results: [(String, Character?)] = []
        tap.onWordBoundary = { word, sep in results.append((word, sep)) }

        for c in "ab" { _ = tap.handleEvent(makeEvent(char: c), type: .keyDown) }
        _ = tap.handleEvent(makeBackspaceEvent(), type: .keyDown)
        _ = tap.handleEvent(makeBackspaceEvent(), type: .keyDown)
        _ = tap.handleEvent(makeBackspaceEvent(), type: .keyDown)
        _ = tap.handleEvent(makeArrowEvent(), type: .keyDown)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].0, "")
    }

    func testSwitchingAppsFlushes() {
        let tap = InputTap()
        var results: [(String, Character?)] = []
        tap.onWordBoundary = { word, sep in results.append((word, sep)) }

        _ = tap.handleEvent(makeEvent(char: "a", pid: 1), type: .keyDown)
        _ = tap.handleEvent(makeEvent(char: "b", pid: 2), type: .keyDown)
        _ = tap.handleEvent(makeArrowEvent(pid: 2), type: .keyDown)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].0, "a")
        XCTAssertEqual(results[1].0, "b")
    }

    func testArrowKeysFlush() {
        let tap = InputTap()
        var results: [(String, Character?)] = []
        tap.onWordBoundary = { word, sep in results.append((word, sep)) }

        for c in "ab" { _ = tap.handleEvent(makeEvent(char: c), type: .keyDown) }
        _ = tap.handleEvent(makeArrowEvent(), type: .keyDown)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].0, "ab")
    }
}
