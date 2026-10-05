#!/usr/bin/env bash
# Build the Tish compiler Moo's plugins are built with: tishlang/tish at TISH_REF with
# TISH_PATCHES applied (toolchain.env), into TISH_DIR (default .toolchain/tish).
# Prints TISH=<compiler> and, under GitHub Actions, adds it to $GITHUB_ENV.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
# shellcheck source=toolchain.env
source "$ROOT/toolchain/toolchain.env"
TISH_DIR="${TISH_DIR:-$ROOT/.toolchain/tish}"
if [ ! -d "$TISH_DIR/.git" ]; then
  mkdir -p "$TISH_DIR"
  git -C "$TISH_DIR" init -q
  git -C "$TISH_DIR" remote add origin https://github.com/tishlang/tish.git
fi
git -C "$TISH_DIR" fetch -q --depth 1 origin "$TISH_REF"
git -C "$TISH_DIR" reset -q --hard FETCH_HEAD
git -C "$TISH_DIR" clean -qfd -e target
for p in $TISH_PATCHES; do
  git -C "$TISH_DIR" apply --whitespace=nowarn "$ROOT/toolchain/patches/$p"
  echo "applied $p"
done
(cd "$TISH_DIR" && cargo build --release -p tishlang --features full)
TISH="$TISH_DIR/target/release/tish"
"$TISH" --version
echo "TISH=$TISH"
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "TISH=$TISH" >> "$GITHUB_ENV"
fi
