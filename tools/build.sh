#!/usr/bin/env bash
# Build LUX targets with Free Pascal (Unix/Linux host).
set -euo pipefail
# shellcheck source=lux_fpc.sh
source "$(cd "$(dirname "$0")" && pwd)/lux_fpc.sh"

ROOT="$(lux_root)"
TARGET="${1:-hello}"

mapfile -t PORTABLE < <(lux_portable_paths "$ROOT")
mapfile -t UNIX < <(lux_unix_paths "$ROOT")

build_one() {
  local source="$1"
  local outname="$2"
  shift 2
  local paths=("$@")
  local out="$ROOT/bin/$outname"
  lux_fpc_compile "$ROOT" "$source" "$out" "${paths[@]}"
  echo "Built: $out"
}

case "$TARGET" in
  hello)
    build_one "$ROOT/examples/hello/hello_lux.pas" hello_lux "${PORTABLE[@]}"
    ;;
  tests)
    build_one "$ROOT/tests/lux_tests.pas" lux_tests "${PORTABLE[@]}"
    ;;
  unix-demo)
    build_one "$ROOT/examples/unix_demo/unix_demo.pas" unix_demo "${UNIX[@]}"
    ;;
  unix-tests)
    build_one "$ROOT/tests/unix/lux_unix_tests.pas" lux_unix_tests "${UNIX[@]}"
    ;;
  all)
    build_one "$ROOT/examples/hello/hello_lux.pas" hello_lux "${PORTABLE[@]}"
    build_one "$ROOT/tests/lux_tests.pas" lux_tests "${PORTABLE[@]}"
    build_one "$ROOT/examples/unix_demo/unix_demo.pas" unix_demo "${UNIX[@]}"
    build_one "$ROOT/tests/unix/lux_unix_tests.pas" lux_unix_tests "${UNIX[@]}"
    ;;
  *)
    echo "Usage: $0 [hello|tests|unix-demo|unix-tests|all]" >&2
    exit 2
    ;;
esac
