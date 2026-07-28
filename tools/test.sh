#!/usr/bin/env bash
# Build and run the LUX portable test suite.
set -euo pipefail
# shellcheck source=lux_fpc.sh
source "$(cd "$(dirname "$0")" && pwd)/lux_fpc.sh"

ROOT="$(lux_root)"
OUT="$ROOT/bin/lux_tests"
lux_fpc_compile "$ROOT" "$ROOT/tests/lux_tests.pas" "$OUT"
echo "Built: $OUT"
"$OUT"
