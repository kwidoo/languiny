import Carbon
import Foundation

struct KeyboardInputSource: Identifiable {
    let id: String
    let name: String
    let languages: [String]
}

final class InputSourcesService {
    static let shared = InputSourcesService()
    private init() {}

    func list() -> [KeyboardInputSource] {
        let filter: [CFString: Any] = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
            kTISPropertyInputSourceType: kTISTypeKeyboardLayout
        ]
        guard let cfList = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return cfList.compactMap { src in
            guard
                let idPtr = TISGetInputSourceProperty(src, kTISPropertyInputSourceID),
                let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String?,
                let namePtr = TISGetInputSourceProperty(src, kTISPropertyLocalizedName),
                let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String?
            else {
                return nil
            }
            let langsPtr = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages)
            let langs = langsPtr != nil ? (Unmanaged<CFArray>.fromOpaque(langsPtr!).takeUnretainedValue() as? [String]) ?? [] : []
            return KeyboardInputSource(id: id, name: name, languages: langs)
        }
    }

    func resolveLayout(for language: String, overrides: [String: String]? = nil) -> KeyboardInputSource? {
        let sources = list()
        if let overrides = overrides, let id = overrides[language], let src = sources.first(where: { $0.id == id }) {
            return src
        }
        return sources.first { $0.languages.contains(language) }
    }
}
