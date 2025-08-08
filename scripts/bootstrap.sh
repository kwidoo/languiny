#!/bin/zsh
set -euo pipefail

# Check Xcode command line tools
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools not found. Install via: xcode-select --install"
  exit 1
fi

# Check Go version
if ! command -v go >/dev/null 2>&1; then
  echo "Go not found. Install Go 1.22+"
  exit 1
fi

REQ_GO=1.22
CUR_GO=$(go env GOVERSION | sed 's/go//')

compare_versions() {
  # returns 0 if $1 >= $2
  autoload -Uz is-at-least || true
  if is-at-least $2 $1; then
    return 0
  else
    return 1
  fi
}

if ! compare_versions "$CUR_GO" "$REQ_GO"; then
  echo "Go $REQ_GO+ required, found $CUR_GO"
  exit 1
fi

echo "Bootstrap OK. Next: make build-engine"
