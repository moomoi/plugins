#!/usr/bin/env bash
# Build every plugin for Windows (x64) and pack them for Moo to download:
#   dist/release/moo-plugins-windows.tar.gz   every <id>.tishc, plus each <id>.lib as a Windows DLL
# Runs on Windows or cross from macOS/Linux with cargo-xwin and LLVM (`cargo install cargo-xwin`;
# `brew install llvm lld` or `apt install clang lld llvm`). Native plugins use FFI ABI v2, which
# names no host symbols, so the DLLs load into any Moo.
set -euo pipefail
cd "$(dirname "$0")/.."
TARGET=x86_64-pc-windows-msvc
OUT=dist/windows
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) ;;
  *)
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
    eval "$(cargo xwin env --target "$TARGET")"
    ;;
esac
rm -rf "$OUT" && mkdir -p "$OUT" dist/release
rm -f dist/*.lib dist/*.tishc
TISH_NATIVE_CARGO_TARGET="$TARGET" bash build.sh
cp dist/*.tishc "$OUT/"
for lib in dist/*.lib; do
  [ -e "$lib" ] && cp "$lib" "$OUT/"
done
tar -czf dist/release/moo-plugins-windows.tar.gz -C "$OUT" .
tar -tzf dist/release/moo-plugins-windows.tar.gz
