#!/usr/bin/env bash
# Build the Phase 0 hello_lux example with Free Pascal.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/bin"
UNIT_OUT="$OUT/units"

mkdir -p "$OUT" "$UNIT_OUT"

FPC="${FPC:-fpc}"

"$FPC" \
  -Mobjfpc \
  -Scghi \
  -O1 \
  -g \
  -gl \
  -vewnhibq \
  -Fu"$ROOT/src/core" \
  -FU"$UNIT_OUT" \
  -FE"$OUT" \
  -o"$OUT/hello_lux" \
  "$ROOT/examples/hello/hello_lux.pas"

echo "Built: $OUT/hello_lux"
