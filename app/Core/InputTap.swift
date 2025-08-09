import ApplicationServices
import Foundation

#if canImport(AppKit)
    import AppKit
#endif

/// Captures global key events using a CGEventTap and forwards
/// characters into a simple word buffer.
final class InputTap {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let wordBuffer = WordBuffer()
    private var activePID: pid_t?

    // Flag to avoid handling events we synthesize ourselves
    private var isInjecting = false
    private var suppressedKeyUp: CGKeyCode?
    private let boundaryMetrics = RollingMetrics(capacity: 100)

    // Debug options
    var injectionEnabled = true
    private let usePasteboardFallback = false

    /// Forward word boundary callbacks to consumers.
    var onWordBoundary: ((String, Character?) -> Void)? {
        get { wordBuffer.onWordBoundary }
        set { wordBuffer.onWordBoundary = newValue }
    }

    init() {
        wordBuffer.onWordBoundary = { [weak self] word, sep in
            self?.handleBoundary(word: word, separator: sep)
        }
    }

    /// Prepare the event tap and run loop source.
    func setup() {
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: InputTap.eventCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        if let tap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        } else {
            Logger.log("Failed to create event tap")
        }
    }

    /// Start listening to keyboard events.
    func start() {
        guard let tap = eventTap, let src = runLoopSource else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
    }

    /// Stop listening and remove run loop source.
    func stop() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
    }

    /// Send backspace events to remove last `count` characters.
    private func suppressKeystrokes(count: Int) {
        guard count > 0 else { return }
        isInjecting = true
        defer { isInjecting = false }
        for _ in 0..<count {
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)
            down?.post(tap: .cghidEventTap)
            let up = CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: false)
            up?.post(tap: .cghidEventTap)
        }
    }

    /// Inject ASCII text into the focused application using synthetic keyboard events.
    private func inject(text: String) {
        guard !text.isEmpty else { return }
        isInjecting = true
        defer { isInjecting = false }

        if usePasteboardFallback {
            #if canImport(AppKit)
                let pasteboard = NSPasteboard.general
                let original = pasteboard.string(forType: .string)
                pasteboard.clearContents()
                pasteboard.setString(text, forType: .string)

                // Send Command+V to paste
                let vKey: CGKeyCode = 9
                let down = CGEvent(keyboardEventSource: nil, virtualKey: vKey, keyDown: true)
                down?.flags = .maskCommand
                down?.post(tap: .cghidEventTap)
                let up = CGEvent(keyboardEventSource: nil, virtualKey: vKey, keyDown: false)
                up?.flags = .maskCommand
                up?.post(tap: .cghidEventTap)

                // Restore previous pasteboard content
                pasteboard.clearContents()
                if let original = original {
                    pasteboard.setString(original, forType: .string)
                }
            #endif
            return
        }

        for scalar in text.unicodeScalars {
            let chars: [UniChar] = [UniChar(scalar.value)]
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: chars)
            down?.post(tap: .cghidEventTap)

            let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: chars)
            up?.post(tap: .cghidEventTap)
        }
    }

    /// Handle a completed word and decide whether to switch layouts and remap.
    private func handleBoundary(word: String, separator: Character?) {
        let start = CFAbsoluteTimeGetCurrent()
        guard let pair = loadLayoutPair(), let currentID = getCurrentLayoutID() else {
            Logger.log("boundary: missing layout info", verbose: true)
            return
        }
        guard autoFixEnabled() else { return }
        let candidate = word.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?:;)]}"))
        if shouldIgnoreUrlsEmails() && looksLikeUrlOrEmail(candidate) {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            boundaryMetrics.record(elapsed)
            Logger.log("ignore: \(word) in \(Int(elapsed))ms (avg \(Int(boundaryMetrics.average()))ms)", verbose: true)
            return
        }
        let currentLayout: Int32
        let targetLayout: Int32
        let targetID: String
        if currentID == pair.fromID {
            currentLayout = 0
            targetLayout = 1
            targetID = pair.toID
        } else if currentID == pair.toID {
            currentLayout = 1
            targetLayout = 0
            targetID = pair.fromID
        } else {
            Logger.log("boundary: current layout not in pair", verbose: true)
            return
        }

        if shouldSwitch(word, current: currentLayout) {
            let mapped = remapWord(word, from: currentLayout, to: targetLayout) ?? word
            let sepCount = separator == nil ? 0 : 1
            suppressKeystrokes(count: word.count + sepCount)
            _ = setLayout(by: targetID)
            let text = mapped + (separator.map { String($0) } ?? "")
            inject(text: text)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            boundaryMetrics.record(elapsed)
            Logger.log("switch: \(word) -> \(mapped) in \(Int(elapsed))ms (avg \(Int(boundaryMetrics.average()))ms)")
        } else {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            boundaryMetrics.record(elapsed)
            Logger.log("no switch: \(word) in \(Int(elapsed))ms (avg \(Int(boundaryMetrics.average()))ms)", verbose: true)
        }
    }

    private func looksLikeUrlOrEmail(_ word: String) -> Bool {
        let trimmed = word.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?:;)]}"))
        // RFC 3986 scheme: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
        if trimmed.range(of: #"^[A-Za-z][A-Za-z0-9+.-]*://"#, options: .regularExpression) != nil {
            return true
        }
        if trimmed.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
                         options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }
        return false
    }

    func handleEvent(_ event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        if isInjecting || !injectionEnabled {
            return Unmanaged.passUnretained(event)
        }

        let pid = pid_t(event.getIntegerValueField(.eventSourceUnixProcessID))
        if let last = activePID, last != pid {
            wordBuffer.flush()
        }
        activePID = pid

        #if canImport(AppKit)
            if let app = NSRunningApplication(processIdentifier: pid),
               let bundleID = app.bundleIdentifier,
               !isAppEnabled(bundleID: bundleID) {
                return Unmanaged.passUnretained(event)
            }
        #endif

        switch type {
        case .tapDisabledByTimeout:
            if let tap = eventTap {
                Logger.log("Event tap disabled by timeout; re-enabling", verbose: true)
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        case .keyDown:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags
            Logger.log("keyDown code=\(keyCode) flags=\(flags.rawValue)", verbose: true)

            let whitelist = loadCmdCtrlWhitelist()
            if (flags.contains(.maskCommand) || flags.contains(.maskControl)) &&
                !whitelist.contains(keyCode) {
                return Unmanaged.passUnretained(event)
            }
            if shouldBypassOption() && flags.contains(.maskAlternate) {
                return Unmanaged.passUnretained(event)
            }

            // Option+Space hotkey -> inject prototype string
            if flags.contains(.maskAlternate) && keyCode == 49 {
                inject(text: "<REPLACED>")
                suppressedKeyUp = keyCode
                return nil
            }

            // Arrow keys flush the buffer
            if [123, 124, 125, 126].contains(Int(keyCode)) {
                wordBuffer.flush()
                return Unmanaged.passUnretained(event)
            }

            // Backspace mutates buffer
            if keyCode == 51 {
                wordBuffer.backspace()
                return Unmanaged.passUnretained(event)
            }

            if let sep = wordBuffer.boundary(for: event) {
                wordBuffer.flush(separator: sep)
            } else {
                var chars = [UniChar](repeating: 0, count: 4)
                var length = 0
                event.keyboardGetUnicodeString(
                    maxStringLength: 4,
                    actualStringLength: &length,
                    unicodeString: &chars
                )
                for i in 0..<length {
                    if let scalar = UnicodeScalar(chars[i]) {
                        wordBuffer.append(Character(scalar))
                    }
                }
            }
        case .keyUp:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags
            if suppressedKeyUp == keyCode {
                suppressedKeyUp = nil
                return nil
            }
            let whitelist = loadCmdCtrlWhitelist()
            if (flags.contains(.maskCommand) || flags.contains(.maskControl)) &&
                !whitelist.contains(keyCode) {
                return Unmanaged.passUnretained(event)
            }
            if shouldBypassOption() && flags.contains(.maskAlternate) {
                return Unmanaged.passUnretained(event)
            }
            Logger.log("keyUp", verbose: true)
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let tap = Unmanaged<InputTap>.fromOpaque(refcon).takeUnretainedValue()
        return tap.handleEvent(event, type: type)
    }
}
