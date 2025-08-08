import Foundation
import AppKit
import ApplicationServices

func isTrustedForAccessibility() -> Bool {
    let options: NSDictionary = [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
    ]
    return AXIsProcessTrustedWithOptions(options)
}

func openAccessibilitySettings() {
    guard let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ) else { return }
    NSWorkspace.shared.open(url)
}
