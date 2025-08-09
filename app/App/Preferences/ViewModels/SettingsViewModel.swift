import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: Settings
    private let store: SettingsStore
    private var token: Any?

    init(store: SettingsStore = .shared) {
        self.store = store
        self.settings = store.settings
        token = NotificationCenter.default.addObserver(forName: .settingsDidChange, object: nil, queue: .main) { [weak self] note in
            if let newSettings = note.object as? Settings {
                self?.settings = newSettings
            }
        }
    }

    func update(_ block: (inout Settings) -> Void) {
        store.update(block)
    }

    func exportData() -> Data? { store.exportData() }
    func importData(_ data: Data) { store.importData(data) }
}
