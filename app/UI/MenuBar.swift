import AppKit
import SwiftUI

final class MenuBar {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var menu: NSMenu!

    init() {
        setup()
    }

    private func setup() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        }
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Enable", action: #selector(toggleEnable), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPrefs), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func toggleEnable() { Logger.log("Toggle enable") }
    @objc private func openPrefs() { Logger.log("Open prefs") }
    @objc private func quit() { NSApp.terminate(nil) }
}

enum Logger {
    static func log(_ msg: String) {
        NSLog("[Languiny] %@", msg)
    }
}
