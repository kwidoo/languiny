import AppKit

final class PreferencesWindowController: NSWindowController {
    private let tabController = NSTabViewController()

    init() {
        super.init(window: nil)
        let window = NSWindow(contentViewController: tabController)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 500, height: 400))
        self.window = window

        let general = GeneralTabViewController()
        general.title = "General"
        tabController.addChild(general)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
