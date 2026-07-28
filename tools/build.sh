#!/usr/bin/env bash
# Build the hello_lux example with Free Pascal (portable).
set -euo pipefail
# shellcheck source=lux_fpc.sh
source "$(cd "$(dirname "$0")" && pwd)/lux_fpc.sh"

ROOT="$(lux_root)"
OUT="$ROOT/bin/hello_lux"
lux_fpc_compile "$ROOT" "$ROOT/examples/hello/hello_lux.pas" "$OUT"
echo "Built: $OUT"
