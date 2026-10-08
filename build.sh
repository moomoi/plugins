#!/usr/bin/env bash
# Build every plugin into dist/, by the tier its moo.json declares:
#   A: bytecode chunk (<id>.tishc), run by Moo in a capability-free VM
#   B: native module (<id>.lib), loaded in-process through tish:ffi
# TISH names the compiler (default: the npm one, from package.json). When this checkout sits
# inside Moo's repo (developing a plugin against Moo), native builds share Moo's target/ directory.
# Releases: scripts/package.sh builds both architectures and packs what Moo downloads.
set -euo pipefail
cd "$(dirname "$0")"
[ -n "${TISH:-}" ] || [ -x node_modules/.bin/tish ] || npm ci --no-audit --no-fund
TISH="${TISH:-$(pwd)/node_modules/.bin/tish}"
unset CARGO_TARGET_DIR
if [ -f ../toolchain.env ]; then
  DEFAULT_TARGET="$(cd .. && pwd)/target/tish-native"
else
  DEFAULT_TARGET="$(pwd)/target/tish-native"
fi
export TISH_NATIVE_TARGET_DIR="${TISH_NATIVE_TARGET_DIR:-$DEFAULT_TARGET}"
field() { # <manifest> <key>
  sed -nE "s/.*\"$2\": *\"([^\"]+)\".*/\1/p" "$1" | head -1
}
mkdir -p dist
for manifest in */moo.json; do
  dir="${manifest%/moo.json}"
  id="$(field "$manifest" id)"
  tier="$(field "$manifest" tier)"
  entry="$dir/$(field "$manifest" entry)"
  case "$tier" in
    A) "$TISH" build "$entry" --target bytecode -o "dist/$id.tishc" ;;
    B) "$TISH" build "$entry" --target native --crate-type cdylib -o "dist/$id.lib" ;;
    *) echo "skip $dir: unknown tier '$tier'"; continue ;;
  esac
  ls -la dist/"$id".*
done
