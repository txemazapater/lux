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
  eventloop)
    build_one "$ROOT/examples/eventloop/eventloop_unix.pas" eventloop_unix "${UNIX[@]}"
    ;;
  controls-demo)
    build_one "$ROOT/examples/controls_demo/controls_demo_unix.pas" controls_demo_unix "${UNIX[@]}"
    ;;
  stack-demo)
    build_one "$ROOT/examples/stack_demo/stack_demo_unix.pas" stack_demo_unix "${UNIX[@]}"
    ;;
  cursor-demo)
    build_one "$ROOT/examples/cursor_demo/cursor_demo_unix.pas" cursor_demo_unix "${UNIX[@]}"
    ;;
  split-demo)
    build_one "$ROOT/examples/split_demo/split_demo_unix.pas" split_demo_unix "${UNIX[@]}"
    ;;
  scroll-demo)
    build_one "$ROOT/examples/scroll_demo/scroll_demo_unix.pas" scroll_demo_unix "${UNIX[@]}"
    ;;
  form-demo)
    build_one "$ROOT/examples/form_demo/form_demo_unix.pas" form_demo_unix "${UNIX[@]}"
    ;;
  all)
    build_one "$ROOT/examples/hello/hello_lux.pas" hello_lux "${PORTABLE[@]}"
    build_one "$ROOT/tests/lux_tests.pas" lux_tests "${PORTABLE[@]}"
    build_one "$ROOT/examples/unix_demo/unix_demo.pas" unix_demo "${UNIX[@]}"
    build_one "$ROOT/tests/unix/lux_unix_tests.pas" lux_unix_tests "${UNIX[@]}"
    build_one "$ROOT/examples/eventloop/eventloop_unix.pas" eventloop_unix "${UNIX[@]}"
    build_one "$ROOT/examples/controls_demo/controls_demo_unix.pas" controls_demo_unix "${UNIX[@]}"
    build_one "$ROOT/examples/stack_demo/stack_demo_unix.pas" stack_demo_unix "${UNIX[@]}"
    build_one "$ROOT/examples/cursor_demo/cursor_demo_unix.pas" cursor_demo_unix "${UNIX[@]}"
    build_one "$ROOT/examples/split_demo/split_demo_unix.pas" split_demo_unix "${UNIX[@]}"
    build_one "$ROOT/examples/scroll_demo/scroll_demo_unix.pas" scroll_demo_unix "${UNIX[@]}"
    build_one "$ROOT/examples/form_demo/form_demo_unix.pas" form_demo_unix "${UNIX[@]}"
    ;;
  *)
    echo "Usage: $0 [hello|tests|unix-demo|unix-tests|eventloop|controls-demo|stack-demo|cursor-demo|split-demo|scroll-demo|form-demo|all]" >&2
    exit 2
    ;;
esac
