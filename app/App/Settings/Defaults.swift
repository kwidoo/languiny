import Foundation

enum Defaults {
    static let settings = Settings(
        languages: .init(primary: "en_US", secondary: "ru_RU"),
        detection: .init(autoDetect: true),
        switching: .init(automatic: true),
        retro: .init(enabled: true),
        rules: .init(minWordLength: 3),
        apps: .init(blacklist: [], whitelist: []),
        layouts: .init(active: [], languageMap: [:]),
        hotkeys: .init(toggle: "cmd+shift+space"),
        ui: .init(showMenuBarIcon: true),
        learning: .init(enabled: true),
        privacy: .init(analytics: false),
        performance: .init(debounceMS: 50),
        startup: .init(launchAtLogin: false),
        version: 2
    )
}
