import XCTest
@testable import Languiny

final class SettingsStoreTests: XCTestCase {
    func testRoundTripCodable() throws {
        let original = Defaults.settings
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDefaultProvisioning() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let store = SettingsStore(directory: tmp)
        let settings = store.load()
        XCTAssertEqual(settings, Defaults.settings)
    }
}
