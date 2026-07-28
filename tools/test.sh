#!/usr/bin/env bash
# Build and run the portable LUX test suite.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/tools/check_portable.sh"
"$ROOT/tools/build.sh" tests
"$ROOT/bin/lux_tests"
