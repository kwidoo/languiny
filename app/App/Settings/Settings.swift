import Foundation

struct LayoutPair: Codable, Equatable {
    var fromID: String
    var toID: String
}

struct Settings: Codable, Equatable {
    struct Languages: Codable, Equatable {
        var primary: String
        var secondary: String
    }

    struct Detection: Codable, Equatable {
        var autoDetect: Bool
    }

    struct Switching: Codable, Equatable {
        var automatic: Bool
        var bypassOption: Bool
        var cmdCtrlWhitelist: [UInt16]
    }

    struct Retro: Codable, Equatable {
        var enabled: Bool
    }

    struct Rules: Codable, Equatable {
        var minWordLength: Int
        var ignoreUrlsEmails: Bool
    }

    struct Apps: Codable, Equatable {
        var blacklist: [String]
        var whitelist: [String]
    }

    struct Layouts: Codable, Equatable {
        var active: [String]
        var languageMap: [String: String]
        var pair: LayoutPair
    }

    struct Hotkeys: Codable, Equatable {
        var toggle: String
    }

    struct UI: Codable, Equatable {
        var showMenuBarIcon: Bool
    }

    struct Learning: Codable, Equatable {
        var enabled: Bool
    }

    struct Privacy: Codable, Equatable {
        var analytics: Bool
    }

    struct Performance: Codable, Equatable {
        var debounceMS: Int
    }

    struct Startup: Codable, Equatable {
        var launchAtLogin: Bool
    }

    var languages: Languages
    var detection: Detection
    var switching: Switching
    var retro: Retro
    var rules: Rules
    var apps: Apps
    var layouts: Layouts
    var hotkeys: Hotkeys
    var ui: UI
    var learning: Learning
    var privacy: Privacy
    var performance: Performance
    var startup: Startup
    var version: Int
}
