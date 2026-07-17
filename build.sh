#!/usr/bin/env bash
# Build machin-herald: one static native binary (CLI only — no server, no wasm).
# Needs `machin` on PATH (or set MACHIN=/path/to/machin).
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
command -v "$MACHIN" >/dev/null 2>&1 || { echo "error: '$MACHIN' not found (set MACHIN=/path/to/machin)"; exit 1; }
"$MACHIN" encode src/herald.src > herald.mfl
"$MACHIN" build herald.mfl -o machin-herald
echo "built ./machin-herald"
echo "try:   ./machin-herald help"
