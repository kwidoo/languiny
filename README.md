# Languiny

A macOS menu bar app that auto-detects and switches keyboard layout while typing. Swift app + Go engine via C interop.

## Stack

- Swift (SwiftUI/AppKit, Quartz/HIToolbox)
- Go 1.22+ (cgo, C ABI)

## Quick Start

```sh
make bootstrap
make build-engine
make build-app
make run
```

## Preferences

The app includes a Preferences window (`⌘,`) where you can:

- Select the pair of keyboard layouts to toggle between.
- Enable or disable behaviors like auto-fix on word boundary, ignoring URLs/emails, and bypassing the Option key.
- Maintain a whitelist or blacklist of application bundle identifiers (one bundle ID per line).

All changes apply immediately and persist across restarts. Settings are stored using `UserDefaults` and can be exported or imported as JSON for easy backup or sharing.

## Layout

```
app/
  App/
  Core/
  UI/
  Bridging/
  Resources/
engine/
  cmd/lib/
  internal/remap/
  internal/detect/
scripts/
docs/
assets/
```

## License

MIT
