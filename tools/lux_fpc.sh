#!/usr/bin/env bash
# Shared Free Pascal helpers for LUX shell scripts.
set -euo pipefail

lux_root() {
  cd "$(dirname "$0")/.." && pwd
}

lux_resolve_fpc() {
  if [[ -n "${FPC:-}" ]]; then
    printf '%s\n' "$FPC"
    return
  fi
  if command -v fpc >/dev/null 2>&1; then
    command -v fpc
    return
  fi
  echo "Free Pascal compiler (fpc) not found. Set FPC to the compiler path." >&2
  exit 1
}

lux_fpc_compile() {
  local root="$1"
  local source="$2"
  local output="$3"
  shift 3
  local unit_paths=("$@")
  local fpc out unit_out args=()
  fpc="$(lux_resolve_fpc)"
  out="$root/bin"
  unit_out="$out/units"
  mkdir -p "$out" "$unit_out"

  local p
  for p in "${unit_paths[@]}"; do
    args+=("-Fu$p")
  done

  "$fpc" \
    -Mobjfpc \
    -Scghi \
    -O1 \
    -g \
    -gl \
    -vewnhibq \
    "${args[@]}" \
    -FU"$unit_out" \
    -FE"$out" \
    -o"$output" \
    "$source"
}

lux_portable_paths() {
  local root="$1"
  printf '%s\n' \
    "$root/src/core" \
    "$root/src/terminal" \
    "$root/src/rendering" \
    "$root/src/events" \
    "$root/src/app" \
    "$root/src/controls" \
    "$root/src/layouts" \
    "$root/tests"
}

lux_unix_paths() {
  local root="$1"
  lux_portable_paths "$root"
  printf '%s\n' \
    "$root/src/platform/unix" \
    "$root/examples/eventloop" \
    "$root/examples/controls_demo" \
    "$root/examples/stack_demo" \
    "$root/examples/cursor_demo" \
    "$root/examples/split_demo"
}
