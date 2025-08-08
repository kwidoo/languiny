import Foundation

struct LayoutPair: Codable {
    let fromID: String
    let toID: String
}

private let layoutPairKey = "layoutPair"
private let bypassOptionKey = "bypassOption"
private let cmdCtrlWhitelistKey = "cmdCtrlWhitelist"
private let appListKey = "appList"
private let appListModeKey = "appListMode"
private let autoFixKey = "autoFixOnBoundary"
private let ignoreURLsKey = "ignoreUrlsEmails"

let layoutPairChangedNotification = Notification.Name("layoutPairChanged")

func loadLayoutPair() -> LayoutPair? {
    guard let data = UserDefaults.standard.data(forKey: layoutPairKey) else {
        return nil
    }
    return try? JSONDecoder().decode(LayoutPair.self, from: data)
}

func saveLayoutPair(_ pair: LayoutPair) {
    if let data = try? JSONEncoder().encode(pair) {
        UserDefaults.standard.set(data, forKey: layoutPairKey)
        NotificationCenter.default.post(name: layoutPairChangedNotification, object: nil)
    }
}

// MARK: - Modifier Options

func shouldBypassOption() -> Bool {
    UserDefaults.standard.bool(forKey: bypassOptionKey)
}

func setBypassOption(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: bypassOptionKey)
}

func loadCmdCtrlWhitelist() -> Set<UInt16> {
    let array = UserDefaults.standard.array(forKey: cmdCtrlWhitelistKey) as? [UInt16] ?? []
    return Set(array)
}

func saveCmdCtrlWhitelist(_ set: Set<UInt16>) {
    UserDefaults.standard.set(Array(set), forKey: cmdCtrlWhitelistKey)
}

// MARK: - Per-app Filtering

enum AppListMode: String {
    case whitelist
    case blacklist
}

func loadAppListMode() -> AppListMode {
    let raw = UserDefaults.standard.string(forKey: appListModeKey) ?? AppListMode.blacklist.rawValue
    return AppListMode(rawValue: raw) ?? .blacklist
}

func saveAppListMode(_ mode: AppListMode) {
    UserDefaults.standard.set(mode.rawValue, forKey: appListModeKey)
}

func loadAppList() -> Set<String> {
    let array = UserDefaults.standard.stringArray(forKey: appListKey) ?? []
    return Set(array)
}

func saveAppList(_ list: Set<String>) {
    UserDefaults.standard.set(Array(list), forKey: appListKey)
}

func isAppEnabled(bundleID: String) -> Bool {
    let list = loadAppList()
    switch loadAppListMode() {
    case .whitelist:
        return list.contains(bundleID)
    case .blacklist:
        return !list.contains(bundleID)
    }
}

func ensureDefaultLayoutPair() {
    if loadLayoutPair() == nil {
        let defaultPair = LayoutPair(fromID: "com.apple.keylayout.US",
                                     toID: "com.apple.keylayout.Russian")
        saveLayoutPair(defaultPair)
    }
}

@discardableResult
func toggleLayoutPair() -> Bool {
    guard let pair = loadLayoutPair(), let current = getCurrentLayoutID() else {
        return false
    }
    let next = current == pair.fromID ? pair.toID : pair.fromID
    return setLayout(by: next)
}

// MARK: - Behavior Options

func autoFixEnabled() -> Bool {
    if UserDefaults.standard.object(forKey: autoFixKey) == nil { return true }
    return UserDefaults.standard.bool(forKey: autoFixKey)
}

func setAutoFixEnabled(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: autoFixKey)
}

func shouldIgnoreUrlsEmails() -> Bool {
    if UserDefaults.standard.object(forKey: ignoreURLsKey) == nil { return true }
    return UserDefaults.standard.bool(forKey: ignoreURLsKey)
}

func setIgnoreUrlsEmails(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: ignoreURLsKey)
}

// MARK: - Export / Import

struct PreferencesData: Codable {
    var layoutPair: LayoutPair
    var bypassOption: Bool
    var cmdCtrlWhitelist: [UInt16]
    var appList: [String]
    var appListMode: String
    var autoFixOnBoundary: Bool
    var ignoreUrlsEmails: Bool
}

func exportPreferences() -> Data? {
    guard let pair = loadLayoutPair() else { return nil }
    let prefs = PreferencesData(
        layoutPair: pair,
        bypassOption: shouldBypassOption(),
        cmdCtrlWhitelist: Array(loadCmdCtrlWhitelist()),
        appList: Array(loadAppList()),
        appListMode: loadAppListMode().rawValue,
        autoFixOnBoundary: autoFixEnabled(),
        ignoreUrlsEmails: shouldIgnoreUrlsEmails()
    )
    return try? JSONEncoder().encode(prefs)
}

func importPreferences(data: Data) {
    guard let prefs = try? JSONDecoder().decode(PreferencesData.self, from: data) else { return }
    saveLayoutPair(prefs.layoutPair)
    setBypassOption(prefs.bypassOption)
    saveCmdCtrlWhitelist(Set(prefs.cmdCtrlWhitelist))
    saveAppList(Set(prefs.appList))
    saveAppListMode(AppListMode(rawValue: prefs.appListMode) ?? .blacklist)
    setAutoFixEnabled(prefs.autoFixOnBoundary)
    setIgnoreUrlsEmails(prefs.ignoreUrlsEmails)
}
