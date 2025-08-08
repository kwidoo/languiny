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

    // Flag to avoid handling events we synthesize ourselves
    private var isInjecting = false
    private var suppressedKeyUp: CGKeyCode?

    // Debug options
    var injectionEnabled = true
    private let usePasteboardFallback = false

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

    private func handleEvent(_ event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        if isInjecting || !injectionEnabled {
            return Unmanaged.passUnretained(event)
        }

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

            // Option+Space hotkey -> inject prototype string
            if flags.contains(.maskAlternate) && keyCode == 49 {
                inject(text: "<REPLACED>")
                suppressedKeyUp = keyCode
                return nil
            }

            if wordBuffer.isBoundary(event: event) {
                wordBuffer.flush()
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
            if suppressedKeyUp == keyCode {
                suppressedKeyUp = nil
                return nil
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
