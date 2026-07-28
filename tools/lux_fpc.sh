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
  local fpc out unit_out
  fpc="$(lux_resolve_fpc)"
  out="$root/bin"
  unit_out="$out/units"
  mkdir -p "$out" "$unit_out"

  "$fpc" \
    -Mobjfpc \
    -Scghi \
    -O1 \
    -g \
    -gl \
    -vewnhibq \
    -Fu"$root/src/core" \
    -Fu"$root/src/rendering" \
    -Fu"$root/tests" \
    -FU"$unit_out" \
    -FE"$out" \
    -o"$output" \
    "$source"
}
