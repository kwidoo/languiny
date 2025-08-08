# Boilerplate Task List (Swift + Go, macOS keyboard layout switcher)

Below is a step-by-step initial assignment to bootstrap a clean monorepo with directories, minimal code, and build scripts for a macOS app (Swift) with a Go engine (via C-interop). Run commands from an empty folder.

## 1) Initialize repository and base files

- Create VCS and core metadata:

  - git init
  - Create files:
    - .gitignore (macOS, Xcode, Go, build artifacts)
    - LICENSE (MIT or your choice)
    - README.md (short project description and build badges placeholder)
    - Makefile (entry point to build tasks)
    - scripts/ directory for automation
    - docs/ directory for design/FFI notes

- .gitignore contents (high level):
  - .DS_Store
  - DerivedData/
  - build/
  - .swiftpm/
  - .xcodeproj/\*
  - xcuserdata/
  - .idea/
  - .vscode/
  - bin/
  - dist/
  - engine/build/
  - engine/bin/
  - engine/pkg/
  - app/.build/
  - app/Build/
  - \*.dSYM
  - \*.dylib
  - \*.a

## 2) Repository structure

- Create directories:

  - app/ (Swift macOS app)
    - App/
    - Core/
    - UI/
    - Bridging/
    - Resources/
  - engine/ (Go algorithmic engine)
    - cmd/lib/ (cgo-exported build target)
    - internal/remap/
    - internal/detect/
  - scripts/
  - docs/
  - assets/

- Provide top-level README.md with:
  - Project overview
  - Stack: Swift (AppKit/SwiftUI + Quartz/HIToolbox) + Go (cgo C-API)
  - Quick start commands
  - Layout overview
  - License notice

## 3) docs: initial specs

- docs/ffi.md:

  - Define initial C ABI between Swift and Go:
    - const char* RemapWord(const char* utf8, int fromLayout, int toLayout);
    - int ShouldSwitch(const char\* utf8, int currentLayout);
    - void FreeCString(const char\* ptr); // engine-owned allocations
  - String encoding: UTF-8, null-terminated
  - Memory ownership: Go returns malloc/cgo allocated strings; Swift must call FreeCString
  - Error signaling: return null for errors from RemapWord; negative values for ShouldSwitch errors

- docs/layouts.md:
  - Target pair: en_US <-> ru_RU
  - Mapping approach: key-to-char tables for both directions
  - Word boundary definition: whitespace, punctuation, Enter
  - Early rules: min word length = 3, ignore URLs/emails patterns

## 4) scripts: bootstrap and build

- scripts/bootstrap.sh:

  - Check Xcode command line tools
  - Check Go version (>=1.22)
  - Print next steps

- scripts/build_engine.sh:

  - Build static lib (default) and dynamic lib targets for macOS (arm64 + optional x86_64 if needed)
  - Output to engine/build/
  - Produce headers (engine/build/include/engine.h)

- scripts/build_app.sh:

  - Build Swift app referencing the engine static lib or dylib
  - Put resulting app bundle to dist/

- scripts/clean.sh:

  - Remove build artifacts: engine/build, dist, app/Build, DerivedData

- All scripts:
  - set -euo pipefail
  - chmod +x on commit

## 5) Makefile to orchestrate

- Targets:
  - bootstrap: run scripts/bootstrap.sh
  - build-engine: run scripts/build_engine.sh
  - build-app: run scripts/build_app.sh
  - build: build-engine then build-app
  - clean: scripts/clean.sh
  - run: open built app bundle
  - fmt: go fmt ./... and swift format placeholder
  - test: go test ./... (later add Swift tests)

## 6) engine: minimal Go library (cgo)

- engine/cmd/lib/engine.go (CGO-exported C-API):

  - Export:
    - RemapWord
    - ShouldSwitch
    - FreeCString
  - Use //export comments and Cgo preamble
  - For now implement stubs:
    - RemapWord returns same string for now
    - ShouldSwitch returns 0
  - Allocate return strings via C.CString; FreeCString frees via C.free

- engine/internal/remap/remap.go:

  - API:
    - func RemapWord(s string, from, to int) (string, error)
  - Stub with identity mapping (placeholders)

- engine/internal/detect/detect.go:

  - API:
    - func ShouldSwitch(s string, current int) (bool, error)
  - Stub returning false

- engine/cmd/lib/engine.h (generated or hand-written first pass):

  - C prototypes matching docs/ffi.md

- go.mod:
  - module path: choose your Git path placeholder (e.g., github.com/you/kbd-switch)
  - Go version 1.22+

## 7) app: minimal Swift macOS target

- Create SwiftPM or Xcode project:

  - For simplicity, start with SwiftPM for sources then add an Xcode project referencing it if preferred.
  - app/App/AppDelegate.swift (AppKit) or main SwiftUI App
  - app/App/KeyboardSwitcherApp.swift (SwiftUI App entry)
  - app/Core/InputTap.swift (skeleton)
  - app/Core/Accessibility.swift (permission check placeholder)
  - app/Core/InputSource.swift (TIS API placeholder)
  - app/Bridging/EngineBridge.swift:
    - C-interop to engine.h
    - Swift functions:
      - func remapWord(\_ s: String, from: Int32, to: Int32) -> String?
      - func shouldSwitch(\_ s: String, current: Int32) -> Bool
    - Handle CString creation and FreeCString

- Linker setup:

  - If static: add engine/build/libengine.a to linking phase and include path to engine/build/include
  - If dynamic: place libengine.dylib in app bundle under Frameworks, set rpath accordingly

- app/UI/MenuBar.swift: minimal status bar icon with menu:

  - Enable/Disable
  - Preferences… (placeholder)
  - Quit

- app/Resources/:
  - App icon placeholder
  - Info.plist with NSAppleEventsUsageDescription and Accessibility usage instructions (in README for now)

## 8) Minimal InputTap skeleton (no real hooks yet)

- app/Core/InputTap.swift:

  - Define a class with setup(), start(), stop() stubs
  - Later: add CGEventTap creation, run loop integration, and event callback

- app/Core/InputSource.swift:

  - Define functions:
    - getCurrentLayoutID() -> String?
    - setLayout(by id: String) -> Bool
  - Leave TODOs with HIToolbox import placeholders

- app/Core/Accessibility.swift:
  - Provide a function isTrustedForAccessibility() -> Bool using AXIsProcessTrustedWithOptions stub call (to be wired later)

## 9) Build and run flow

- Ensure build-engine builds first to generate header and library
- Build app which includes engine.h in a module map or bridging header
- Run app: should launch a menu bar item and call into engine via a simple test call on startup (log return values)

## 10) Initial logging and diagnostics

- Add a tiny Logger wrapper in Swift printing to Console.app
- On app launch:
  - Log Go engine version (hardcode a function GetVersion later)
  - Call RemapWord("test", 0, 1) and log the result

## 11) Security and signing (deferred)

- Note in README:
  - For CGEventTap and synthetic events, app will require Accessibility permission
  - For local runs, signing is not required; for distribution, set up Developer ID later
  - Dynamic libraries may require codesign within the app bundle

## 12) Quick start commands

- In README.md, include:

  - Clone and bootstrap:

    - make bootstrap

  - Build engine:

    - make build-engine

  - Build app:

    - make build-app

  - Run:

    - make run

  - Clean:
    - make clean

## 13) Future tasks backlog (post-boilerplate)

- Implement actual CGEventTap with suppression and injection
- Implement TIS input source enumeration and switching
- Implement layouts mapping tables en_US <-> ru_RU
- Implement real detect/remap logic in Go and tests
- Add whitelist/blacklist apps handling
- Preferences UI with persisted settings (UserDefaults)

---

Below are starter contents for key files.

1. scripts/bootstrap.sh

- Purpose: verify tools.

2. scripts/build_engine.sh

- Purpose: build libengine.a and libengine.dylib.

3. scripts/build_app.sh

- Purpose: compile Swift app and link engine.

4. scripts/clean.sh

- Purpose: clean artifacts.

5. Makefile

- Purpose: orchestrate tasks.

6. engine/cmd/lib/engine.go

- Purpose: CGO-exported C API stubs.

7. engine/internal/remap/remap.go and engine/internal/detect/detect.go

- Purpose: internal logic stubs.

8. engine/cmd/lib/engine.h

- Purpose: C header matching exported functions.

9. app/Bridging/EngineBridge.swift

- Purpose: Swift wrapper over C API.

10. README.md

- Purpose: top-level instructions.

If desired, I can provide minimal file contents for each of the above to paste directly.

Sources
