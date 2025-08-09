import Foundation

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

final class SettingsStore {
    static let shared = SettingsStore()

    private let url: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private(set) var settings: Settings

    init(directory: URL? = nil) {
        let baseDir: URL
        if let directory = directory {
            baseDir = directory
        } else {
            let fm = FileManager.default
            baseDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Languiny", isDirectory: true)
        }
        url = baseDir.appendingPathComponent("settings.json")
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        settings = Defaults.settings
        _ = load()
    }

    @discardableResult
    func load() -> Settings {
        if let data = try? Data(contentsOf: url),
           let migrated = try? SettingsMigration.migrateIfNeeded(data),
           let decoded = try? decoder.decode(Settings.self, from: migrated) {
            settings = decoded
        } else {
            settings = Defaults.settings
            save()
        }
        return settings
    }

    func update(_ block: (inout Settings) -> Void) {
        block(&settings)
        save()
        NotificationCenter.default.post(name: .settingsDidChange, object: settings)
    }

    func exportData() -> Data? {
        try? encoder.encode(settings)
    }

    func importData(_ data: Data) {
        if let decoded = try? decoder.decode(Settings.self, from: data) {
            settings = decoded
            save()
            NotificationCenter.default.post(name: .settingsDidChange, object: settings)
        }
    }

    private func save() {
        if let data = try? encoder.encode(settings) {
            try? data.write(to: url, options: [.atomic])
        }
    }
}
