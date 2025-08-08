import Foundation

struct LayoutPair: Codable {
    let fromID: String
    let toID: String
}

private let layoutPairKey = "layoutPair"

func loadLayoutPair() -> LayoutPair? {
    guard let data = UserDefaults.standard.data(forKey: layoutPairKey) else {
        return nil
    }
    return try? JSONDecoder().decode(LayoutPair.self, from: data)
}

func saveLayoutPair(_ pair: LayoutPair) {
    if let data = try? JSONEncoder().encode(pair) {
        UserDefaults.standard.set(data, forKey: layoutPairKey)
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
