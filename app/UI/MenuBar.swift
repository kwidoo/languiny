import AppKit
import SwiftUI

final class MenuBar {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var menu: NSMenu!
    private var toggleItem: NSMenuItem!
    private var optionBypassItem: NSMenuItem!
    private var appModeItem: NSMenuItem!

    init() {
        setup()
    }

    private func setup() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
            button.image?.isTemplate = true
        }
        menu = NSMenu()
        toggleItem = NSMenuItem(title: "Toggle Layout", action: #selector(toggleLayout), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem(title: "Enable", action: #selector(toggleEnable), keyEquivalent: ""))
        optionBypassItem = NSMenuItem(title: "Bypass Option Keys", action: #selector(toggleOptionBypass), keyEquivalent: "")
        optionBypassItem.state = shouldBypassOption() ? .on : .off
        menu.addItem(optionBypassItem)
        appModeItem = NSMenuItem(title: "Whitelist Mode", action: #selector(toggleAppMode), keyEquivalent: "")
        appModeItem.state = loadAppListMode() == .whitelist ? .on : .off
        menu.addItem(appModeItem)
        menu.addItem(NSMenuItem(title: "Toggle Current App", action: #selector(toggleCurrentApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPrefs), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
        updateToggleTitle()
    }

    func updateAccessibilityStatus(_ trusted: Bool) {
        DispatchQueue.main.async {
            self.statusItem.button?.contentTintColor = trusted ? .systemGreen : .systemRed
            self.statusItem.button?.toolTip = trusted ? "Accessibility: Enabled" : "Accessibility: Missing"
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
    @objc private func toggleEnable() { Logger.log("Toggle enable") }
    @objc private func toggleOptionBypass() {
        let newValue = !shouldBypassOption()
        setBypassOption(newValue)
        optionBypassItem.state = newValue ? .on : .off
    }
    @objc private func toggleAppMode() {
        let newMode: AppListMode = loadAppListMode() == .whitelist ? .blacklist : .whitelist
        saveAppListMode(newMode)
        appModeItem.state = newMode == .whitelist ? .on : .off
    }
    @objc private func toggleCurrentApp() {
        if let app = NSWorkspace.shared.frontmostApplication, let id = app.bundleIdentifier {
            var list = loadAppList()
            if list.contains(id) {
                list.remove(id)
            } else {
                list.insert(id)
            }
            saveAppList(list)
        }
    }
    @objc private func openPrefs() { Logger.log("Open prefs") }
    @objc private func quit() { NSApp.terminate(nil) }
}
