#!/usr/bin/env bash
# Build every plugin into dist/, by the tier its moo.json declares:
#   A: bytecode chunk (<id>.tishc), run by Moo in a capability-free VM
#   B: native module (<id>.lib), loaded in-process through tish:ffi
# TISH names the compiler (toolchain/build.sh builds the pinned one). Inside Moo's own repo, where
# this repo is the plugins/ submodule, native builds share Moo's target/ directory.
set -euo pipefail
cd "$(dirname "$0")"
TISH="${TISH:-/Users/a_/Projects/tish/tish-nimble/target/release/tish}"
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
