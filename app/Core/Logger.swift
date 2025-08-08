import Foundation

/// Simple logger with optional verbose output.
enum Logger {
    static var isVerbose = false

    static func log(_ msg: String, verbose: Bool = false) {
        if verbose && !isVerbose { return }
        NSLog("[Languiny] %@", msg)
    }
}
