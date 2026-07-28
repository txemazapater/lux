#!/usr/bin/env bash
# Optional interactive Unix TTY integration tests.
set -euo pipefail
# shellcheck source=lux_fpc.sh
source "$(cd "$(dirname "$0")" && pwd)/lux_fpc.sh"

ROOT="$(lux_root)"
mapfile -t UNIX < <(lux_unix_paths "$ROOT")
OUT="$ROOT/bin/lux_unix_integration_tests"
lux_fpc_compile "$ROOT" "$ROOT/tests/unix/lux_unix_integration_tests.pas" "$OUT" "${UNIX[@]}"
echo "Built: $OUT"
"$OUT"
