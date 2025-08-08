import Foundation
import Carbon

struct InputSourceInfo: Identifiable {
    let id: String
    let name: String
    let languages: [String]
}

/// Returns enabled keyboard input sources with their identifiers, localized
/// names and language tags. Only keyboard layouts are included.
func listInputSources() -> [InputSourceInfo] {
    let filter: [CFString: Any] = [
        kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
        kTISPropertyInputSourceType: kTISTypeKeyboardLayout,
        kTISPropertyInputSourceIsEnabled: true
    ]
    guard let cfList = TISCreateInputSourceList(filter as CFDictionary, false)
        .takeRetainedValue() as? [TISInputSource] else {
        return []
    }
    return cfList.compactMap { src in
        guard
            let id = TISGetInputSourceProperty(src, kTISPropertyInputSourceID)?
                .takeUnretainedValue() as? String,
            let name = TISGetInputSourceProperty(src, kTISPropertyLocalizedName)?
                .takeUnretainedValue() as? String
        else { return nil }
        let langs = (TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages)?
            .takeUnretainedValue() as? [String]) ?? []
        return InputSourceInfo(id: id, name: name, languages: langs)
    }
}

/// Returns the identifier of the current keyboard layout.
func getCurrentLayoutID() -> String? {
    guard let src = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
        return nil
    }
    return TISGetInputSourceProperty(src, kTISPropertyInputSourceID)?
        .takeUnretainedValue() as? String
}

/// Activates the input source matching the provided identifier.
@discardableResult
func setLayout(by id: String) -> Bool {
    let filter: [CFString: Any] = [kTISPropertyInputSourceID: id]
    guard let list = TISCreateInputSourceList(filter as CFDictionary, false)
        .takeRetainedValue() as? [TISInputSource], let src = list.first else {
        return false
    }
    return TISSelectInputSource(src) == noErr
}
