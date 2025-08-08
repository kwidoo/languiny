import SwiftUI

@main
struct KeyboardSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBar!

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.log("Languiny starting…")
        menuBar = MenuBar()
        // Test engine calls
        let word = remapWord("test", from: 0, to: 1) ?? "<nil>"
        Logger.log("RemapWord => \(word)")
        let sw = shouldSwitch("hello", current: 0)
        Logger.log("ShouldSwitch => \(sw)")
    }
}
