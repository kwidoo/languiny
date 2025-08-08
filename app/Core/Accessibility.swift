import Foundation
import ApplicationServices

func isTrustedForAccessibility() -> Bool {
    // Placeholder: consult AXIsProcessTrustedWithOptions later
    return AXIsProcessTrusted()
}
