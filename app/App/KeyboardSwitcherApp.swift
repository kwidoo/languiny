import AppKit
import SwiftUI

@main
struct KeyboardSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            Text("Placeholder for Settings")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBar!
    private var axTimer: Timer?
    private let tap = InputTap()
    private var enabled = true
    private let settingsStore = SettingsStore.shared

    func applicationWillTerminate(_ notification: Notification) {
        axTimer?.invalidate()
        axTimer = nil
        tap.stop()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = settingsStore.load()
        Logger.log("Languiny starting…")
        menuBar = MenuBar()
        menuBar.onToggleEnable = { [weak self] newValue in
            self?.setProcessing(newValue)
        }
        ensureDefaultLayoutPair()
        menuBar.updateToggleTitle()
        let trusted = isTrustedForAccessibility()
        menuBar.updateStatus(enabled: enabled, axGranted: trusted)
        startAXStatusTimer()
        if trusted {
            tap.setup()
            tap.start()
        } else {
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
            self.menuBar.updateStatus(enabled: self.enabled, axGranted: trusted)
        }
        axTimer?.tolerance = 0.5
    }

    private func promptForAccessibility() {
        while !isTrustedForAccessibility() {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.alertStyle = .warning
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
        tap.setup()
        tap.start()
        menuBar.updateStatus(enabled: enabled, axGranted: true)
    }

    private func setProcessing(_ newValue: Bool) {
        enabled = newValue
        if newValue {
            tap.start()
        } else {
            tap.stop()
        }
        menuBar.updateStatus(enabled: newValue, axGranted: isTrustedForAccessibility())
    }
}
