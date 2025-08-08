import AppKit
import ApplicationServices
import Foundation

func isTrustedForAccessibility() -> Bool {
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options: NSDictionary = [promptKey: false]
    return AXIsProcessTrustedWithOptions(options)
}

func openAccessibilitySettings() {
    guard
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    else { return }

    if !NSWorkspace.shared.open(url) {
        // Fallback to the Security & Privacy pane if deep link fails
        if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            _ = NSWorkspace.shared.open(fallback)
        }
    }
}
