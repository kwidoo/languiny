import Carbon
import Foundation

struct InputSourceInfo: Identifiable {
    let id: String
    let name: String
    let languages: [String]
}

/// Returns enabled keyboard input sources with their identifiers, localized
/// names and language tags. Only keyboard layouts are included.
func listInputSources() -> [InputSourceInfo] {
    let filter: [CFString: Any] = [
        kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource as CFString,
        kTISPropertyInputSourceType: kTISTypeKeyboardLayout as CFString,
        kTISPropertyInputSourceIsEnabled: true,
    ]
    guard
        let cfList = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue()
            as? [TISInputSource]
    else {
        return []
    }
    return cfList.compactMap { src in
        guard
            let idPointer = TISGetInputSourceProperty(src, kTISPropertyInputSourceID),
            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String?,
            let namePointer = TISGetInputSourceProperty(src, kTISPropertyLocalizedName),
            let name = Unmanaged<CFString>.fromOpaque(namePointer).takeUnretainedValue() as String?
        else { return nil }
        let langsPointer = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages)
        let langs =
            langsPointer != nil
            ? (Unmanaged<CFArray>.fromOpaque(langsPointer!).takeUnretainedValue() as? [String])
                ?? [] : []
        return InputSourceInfo(id: id, name: name, languages: langs)
    }
}

/// Returns the identifier of the current keyboard layout.
func getCurrentLayoutID() -> String? {
    guard let src = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
        return nil
    }
    guard let idPointer = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) else {
        return nil
    }
    return Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String?
}

/// Activates the input source matching the provided identifier.
@discardableResult
func setLayout(by id: String) -> Bool {
    let filter: [CFString: Any] = [kTISPropertyInputSourceID: id as CFString]
    guard
        let list = TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue()
            as? [TISInputSource], let src = list.first
    else {
        return false
    }
    return TISSelectInputSource(src) == noErr
}
