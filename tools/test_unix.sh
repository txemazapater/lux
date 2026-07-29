#!/usr/bin/env bash
# Build and run Unix platform unit tests (no interactive TTY required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/tools/build.sh" unix-tests
"$ROOT/bin/lux_unix_tests"
