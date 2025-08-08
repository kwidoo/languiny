#!/bin/zsh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP="$ROOT/app"
DIST="$ROOT/dist"
ENG_OUT="$ROOT/engine/build"
INC="$ENG_OUT/include"
LIB="$ENG_OUT"

mkdir -p "$DIST"

# Ensure engine is built
if [ ! -f "$LIB/libengine.a" ]; then
  echo "Engine not built. Run: make build-engine"
  exit 1
fi

# Use SwiftPM to build a minimal app and then create a bundle
# Create Package.swift if missing
if [ ! -f "$APP/Package.swift" ]; then
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
                .unsafeFlags(["-L\(LIB_PATH)", "-lengine", "-rpath", "@executable_path/../Frameworks"]) 
            ]
        )
    ]
)
SWIFT
fi

# Build app with library path injected
LIB_PATH_ESCAPED=${LIB//\//\\/}
sed -i '' "s|(LIB_PATH)|$LIB_PATH_ESCAPED|g" "$APP/Package.swift"

# Provide module map via bridging header search path
export CGO_CFLAGS="-I$INC"
export CGO_LDFLAGS="-L$LIB -lengine"

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
# Copy dynamic lib to bundle for runtime (even if we link static)
cp "$LIB/libengine.dylib" "$FRAMEWORKS/"

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
</dict>
</plist>
PLIST

# Copy resources
rsync -a "$APP/Resources/" "$RESOURCES/" || true

echo "App bundle at $APP_BUNDLE"
