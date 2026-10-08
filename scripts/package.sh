#!/usr/bin/env bash
# Build every plugin for Apple silicon and Intel and pack them for Moo to download:
#   dist/release/moo-plugins.tar.gz   every <id>.tishc, plus each <id>.lib as one universal file
#   dist/release/SHA256SUMS
# Bytecode (.tishc) is the same on both; native (.lib) plugins are built per triple and lipo'd.
set -euo pipefail
cd "$(dirname "$0")/.."
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"
OUT=dist/universal
SLICES=dist/slices
rm -rf "$OUT" "$SLICES" dist/release
mkdir -p "$OUT" "$SLICES" dist/release

for triple in aarch64-apple-darwin x86_64-apple-darwin; do
  echo "== $triple"
  rm -f dist/*.lib dist/*.tishc
  TISH_NATIVE_CARGO_TARGET="$triple" bash build.sh
  mkdir -p "$SLICES/$triple"
  for lib in dist/*.lib; do
    [ -e "$lib" ] && cp "$lib" "$SLICES/$triple/"
  done
done
cp dist/*.tishc "$OUT/"
for lib in "$SLICES"/aarch64-apple-darwin/*.lib; do
  [ -e "$lib" ] || continue
  name="$(basename "$lib")"
  lipo -create "$lib" "$SLICES/x86_64-apple-darwin/$name" -output "$OUT/$name"
  archs="$(lipo -archs "$OUT/$name")"
  echo "$name: $archs"
  case "$archs" in
    *x86_64*arm64* | *arm64*x86_64*) ;;
    *) echo "error: $name is not universal" >&2; exit 1 ;;
  esac
done

tar -czf dist/release/moo-plugins.tar.gz -C "$OUT" .
(cd dist/release && shasum -a 256 moo-plugins.tar.gz > SHA256SUMS)
tar -tzf dist/release/moo-plugins.tar.gz
cat dist/release/SHA256SUMS
