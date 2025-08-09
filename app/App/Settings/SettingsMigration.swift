import Foundation

enum SettingsMigration {
    /// Placeholder for future migrations. Returns the input data unchanged for v1.
    static func migrateIfNeeded(_ data: Data) throws -> Data {
        // In the future, inspect JSON and migrate older versions here.
        return data
    }
}
