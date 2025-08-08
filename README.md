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
