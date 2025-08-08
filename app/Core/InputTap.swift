import Foundation
import ApplicationServices

/// Captures global key events using a CGEventTap and forwards
/// characters into a simple word buffer.
final class InputTap {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let wordBuffer = WordBuffer()

    /// Prepare the event tap and run loop source.
    func setup() {
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.keyDown.rawValue) |
                   (1 << CGEventType.keyUp.rawValue)

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

    private func handleEvent(_ event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout:
            if let tap = eventTap {
                Logger.log("Event tap disabled by timeout; re-enabling", verbose: true)
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        case .keyDown:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags.rawValue
            Logger.log("keyDown code=\(keyCode) flags=\(flags)", verbose: true)

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
            Logger.log("keyUp", verbose: true)
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon = refcon, let event = event else { return nil }
        let tap = Unmanaged<InputTap>.fromOpaque(refcon).takeUnretainedValue()
        return tap.handleEvent(event, type: type)
    }
}
