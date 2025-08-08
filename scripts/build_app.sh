#!/bin/zsh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP="$ROOT/app"
DIST="$ROOT/dist"
ENG_OUT="$ROOT/engine/build"
INC="$ENG_OUT/include"
LIB="$ENG_OUT"
LIB_A="$ENG_OUT/libengine.a"

mkdir -p "$DIST"

# Ensure engine is built
if [ ! -f "$LIB_A" ]; then
  echo "Engine not built. Run: make build-engine"
  exit 1
fi

# Always regenerate Package.swift to ensure clean flags
cat > "$APP/Package.swift" <<'SWIFT'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LanguinyApp",
    platforms: [ .macOS(.v13) ],
    products: [ .executable(name: "Languiny", targets: ["Languiny"]) ],
    targets: [
        .executableTarget(
            name: "Languiny",
            path: ".",
            exclude: ["Resources"],
            sources: ["App", "Core", "UI", "Bridging"],
            resources: [ .process("Resources") ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-force_load", "-Xlinker", "__LIB_A__"]) 
            ]
        )
    ]
)
SWIFT

# Inject static lib path (use @ delimiter to avoid escaping slashes)
sed -i '' "s@__LIB_A__@$LIB_A@g" "$APP/Package.swift"

# Provide headers for any cgo-produced headers if needed
export CGO_CFLAGS="-I$INC"

# Build
(cd "$APP" && swift build -c release)

# Create a simple .app bundle wrapping the executable
APP_NAME="Languiny"
APP_BUNDLE="$DIST/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
FRAMEWORKS="$CONTENTS/Frameworks"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$FRAMEWORKS" "$RESOURCES"

cp "$APP/.build/release/Languiny" "$MACOS/$APP_NAME"

# Basic Info.plist
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>com.example.languiny</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>This app may use Apple Events to integrate with macOS features.</string>
  <key>NSSystemAdministrationUsageDescription</key>
  <string>Accessibility permissions are required for keyboard monitoring via event taps.</string>
</dict>
</plist>
PLIST

# Copy resources
rsync -a "$APP/Resources/" "$RESOURCES/" || true

# Ad-hoc sign bundle for local runs
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" || true
fi

echo "App bundle at $APP_BUNDLE"
