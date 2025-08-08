import Foundation
import engine

public func remapWord(_ s: String, from: Int32, to: Int32) -> String? {
    return s.withCString { cstr in
        guard let res = RemapWord(cstr, from, to) else { return nil }
        defer { FreeCString(res) }
        return String(cString: res)
    }
}

public func shouldSwitch(_ s: String, current: Int32) -> Bool {
    return s.withCString { cstr in
        ShouldSwitch(cstr, current) > 0
    }
}
