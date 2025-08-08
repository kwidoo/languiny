import Foundation
import AppKit
import ApplicationServices

func isTrustedForAccessibility() -> Bool {
    let options: [CFString: Any] = [
        kAXTrustedCheckOptionPrompt: false,
    ]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

func openAccessibilitySettings() {
    guard let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    ) else { return }
    NSWorkspace.shared.open(url)
}
