#!/bin/zsh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENG="$ROOT/engine"
OUT="$ENG/build"
INCLUDE="$OUT/include"
LIB="$OUT"

mkdir -p "$INCLUDE" "$LIB"

# Create go.mod if missing
if [ ! -f "$ENG/go.mod" ]; then
  (cd "$ENG" && go mod init github.com/you/kbd-switch && go mod tidy)
fi

# Build static lib
(cd "$ENG/cmd/lib" && go build -buildmode=c-archive -o "$LIB/libengine.a")
# Copy header
cp "$ENG/cmd/lib/libengine.h" "$INCLUDE/engine.h"

# Build dynamic lib (optional)
(cd "$ENG/cmd/lib" && go build -buildmode=c-shared -o "$LIB/libengine.dylib")

echo "Engine built at $OUT"
