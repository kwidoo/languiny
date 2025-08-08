import SwiftUI
import AppKit

@main
struct KeyboardSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBar!
    private var axTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.log("Languiny starting…")
        menuBar = MenuBar()
        menuBar.updateAccessibilityStatus(isTrustedForAccessibility())
        startAXStatusTimer()
        if !isTrustedForAccessibility() {
            promptForAccessibility()
        }
        // Test engine calls
        let word = remapWord("test", from: 0, to: 1) ?? "<nil>"
        Logger.log("RemapWord => \(word)")
        let sw = shouldSwitch("hello", current: 0)
        Logger.log("ShouldSwitch => \(sw)")
    }

    private func startAXStatusTimer() {
        axTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let trusted = isTrustedForAccessibility()
            self.menuBar.updateAccessibilityStatus(trusted)
        }
    }

    private func promptForAccessibility() {
        while !isTrustedForAccessibility() {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText =
                "Please enable Accessibility for Languiny in System Settings → Privacy & Security → Accessibility."
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Retry")
            alert.addButton(withTitle: "Quit")
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                openAccessibilitySettings()
            case .alertSecondButtonReturn:
                continue
            default:
                NSApp.terminate(nil)
                return
            }
        }
        menuBar.updateAccessibilityStatus(true)
    }
}
