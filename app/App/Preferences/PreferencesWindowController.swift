import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    private let hostingController: NSHostingController<PreferencesRootView>

    init() {
        hostingController = NSHostingController(rootView: PreferencesRootView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 600, height: 500))
        window.minSize = NSSize(width: 560, height: 400)
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
