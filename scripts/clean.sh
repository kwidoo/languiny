#!/bin/zsh
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
rm -rf "$ROOT/engine/build" "$ROOT/dist" "$ROOT/app/.build" "$ROOT/DerivedData" "$ROOT/app/Build"
echo "Cleaned"
