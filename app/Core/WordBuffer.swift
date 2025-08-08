import Foundation
import ApplicationServices

/// Collects characters into a word and flushes on boundary events.
final class WordBuffer {
    private var buffer: [Character] = []

    func append(_ char: Character) {
        buffer.append(char)
        Logger.log("buffer: \(String(buffer))", verbose: true)
    }

    /// Detect separators such as space or newline.
    func isBoundary(event: CGEvent) -> Bool {
        var chars = [UniChar](repeating: 0, count: 1)
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 1, actualStringLength: &length, unicodeString: &chars)
        guard length == 1, let scalar = UnicodeScalar(chars[0]) else { return false }
        return CharacterSet.whitespacesAndNewlines.contains(scalar)
    }

    func flush() {
        if !buffer.isEmpty {
            Logger.log("flush: \(String(buffer))", verbose: true)
            buffer.removeAll()
        }
    }
}
