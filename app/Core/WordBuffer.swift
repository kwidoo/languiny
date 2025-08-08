import Foundation
import ApplicationServices

/// Collects characters into a word and flushes on boundary events.
final class WordBuffer {
    private var buffer: [Character] = []

    /// Callback invoked when a word boundary is detected.
    var onWordBoundary: ((String, Character?) -> Void)?

    /// Append a character to the buffer.
    func append(_ char: Character) {
        buffer.append(char)
        Logger.log("buffer: \(String(buffer))", verbose: true)
    }

    /// Remove the last character if available.
    func backspace() {
        if !buffer.isEmpty { buffer.removeLast() }
        Logger.log("buffer: \(String(buffer))", verbose: true)
    }

    /// Clear the buffer entirely.
    func reset() {
        buffer.removeAll()
    }

    /// Determine if a key event represents a word boundary and return the separator.
    func boundary(for event: CGEvent) -> Character? {
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        guard length > 0 else { return nil }
        for i in 0..<length {
            guard let scalar = UnicodeScalar(chars[i]) else { continue }
            if CharacterSet.whitespacesAndNewlines.contains(scalar) ||
                CharacterSet.punctuationCharacters.contains(scalar) {
                return Character(scalar)
            }
        }
        return nil
    }

    /// Flush the current buffer and emit boundary callback.
    func flush(separator: Character? = nil) {
        let word = String(buffer)
        buffer.removeAll()
        if !word.isEmpty || separator != nil {
            Logger.log("flush: \(word) sep=\(String(describing: separator))", verbose: true)
            onWordBoundary?(word, separator)
        }
    }
}
