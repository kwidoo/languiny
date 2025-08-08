import AppKit
import SwiftUI

final class MenuBar {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var menu: NSMenu!
    private var toggleItem: NSMenuItem!
    private var enableItem: NSMenuItem!
    private var prefsWindow: NSWindow?

    private var isEnabled = true
    var onToggleEnable: ((Bool) -> Void)?

    init() {
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(handleLayoutPairChange), name: layoutPairChangedNotification, object: nil)
    }

    private func setup() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
            button.image?.isTemplate = true
        }
        menu = NSMenu()
        enableItem = NSMenuItem(title: "Disable", action: #selector(toggleEnable), keyEquivalent: "")
        menu.addItem(enableItem)
        toggleItem = NSMenuItem(title: "Toggle Layout", action: #selector(toggleLayout), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPrefs), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About Languiny", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
        updateToggleTitle()
    }

    func updateStatus(enabled: Bool, axGranted: Bool) {
        setEnabled(enabled)
        updateAccessibility(axGranted)
    }

    private func updateAccessibility(_ trusted: Bool) {
        DispatchQueue.main.async {
            self.statusItem.button?.contentTintColor = trusted ? .controlAccentColor : .systemRed
            self.statusItem.button?.toolTip = trusted ? "Accessibility: Enabled" : "Accessibility: Missing"
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        DispatchQueue.main.async {
            self.enableItem.title = enabled ? "Disable" : "Enable"
            let symbol = enabled ? "keyboard" : "keyboard.slash"
            self.statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            self.statusItem.button?.image?.isTemplate = true
        }
    }

    func updateToggleTitle() {
        DispatchQueue.main.async {
            if let pair = loadLayoutPair(), let currentID = getCurrentLayoutID() {
                let otherID = currentID == pair.fromID ? pair.toID : pair.fromID
                let name = listInputSources().first { $0.id == otherID }?.name ?? "Toggle Layout"
                self.toggleItem.title = "Switch to \(name)"
            } else {
                self.toggleItem.title = "Toggle Layout"
            }
        }
    }

    @objc private func toggleLayout() {
        if toggleLayoutPair() { updateToggleTitle() }
    }

    @objc private func toggleEnable() {
        setEnabled(!isEnabled)
        onToggleEnable?(isEnabled)
    }

    @objc private func openPrefs() {
        if prefsWindow == nil {
            let controller = NSHostingController(rootView: PreferencesView())
            let window = NSWindow(contentViewController: controller)
            window.title = "Preferences"
            prefsWindow = window
        }
        prefsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAbout() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let engineVer = engineVersion()
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationVersion: "\(appVersion) (Engine \(engineVer))"
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func handleLayoutPairChange() { updateToggleTitle() }
}
