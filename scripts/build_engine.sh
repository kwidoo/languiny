#!/bin/zsh
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENG="$ROOT/engine"
OUT="$ENG/build"
INCLUDE="$OUT/include"
LIB="$OUT"

# Align Go cgo build with app's deployment target to avoid linker warnings
export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-13.0}
export CGO_ENABLED=1
export GOOS=darwin
export GOARCH=arm64
export CGO_CFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
export CGO_LDFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

mkdir -p "$INCLUDE" "$LIB"

# Create go.mod if missing
if [ ! -f "$ENG/go.mod" ]; then
  (cd "$ENG" && go mod init github.com/kwidoo/languiny && go mod tidy)
fi

# Build static lib
(cd "$ENG/cmd/lib" && go build -buildmode=c-archive -o "$LIB/libengine.a")
# Copy header
cp "$ENG/cmd/lib/libengine.h" "$INCLUDE/engine.h"

# Build dynamic lib (optional)
(cd "$ENG/cmd/lib" && go build -buildmode=c-shared -o "$LIB/libengine.dylib")

echo "Engine built at $OUT"
