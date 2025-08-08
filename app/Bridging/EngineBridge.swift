import Foundation

// C prototypes bridged from engine header
@_silgen_name("RemapWord")
private func C_RemapWord(_ utf8: UnsafePointer<CChar>?, _ fromLayout: Int32, _ toLayout: Int32) -> UnsafeMutablePointer<CChar>?

@_silgen_name("ShouldSwitch")
private func C_ShouldSwitch(_ utf8: UnsafePointer<CChar>?, _ currentLayout: Int32) -> Int32

@_silgen_name("FreeCString")
private func C_FreeCString(_ ptr: UnsafeMutablePointer<CChar>?)

func remapWord(_ s: String, from: Int32, to: Int32) -> String? {
    return s.withCString { cstr in
        guard let res = C_RemapWord(cstr, from, to) else { return nil }
        defer { C_FreeCString(res) }
        return String(cString: res)
    }
}

func shouldSwitch(_ s: String, current: Int32) -> Bool {
    return s.withCString { cstr in
        let v = C_ShouldSwitch(cstr, current)
        return v > 0
    }
}
