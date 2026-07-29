#!/usr/bin/env bash
# Fail if portable units reference Win32/Unix console APIs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATTERN='uses[[:space:]]+Windows\b|Windows\.|GetConsoleMode|SetConsoleMode|termios|kernel32'
FAILED=0

while IFS= read -r -d '' file; do
  if grep -E "$PATTERN" "$file" >/dev/null; then
    echo "PORTABLE VIOLATION: $file"
    FAILED=1
  fi
done < <(find "$ROOT/src/core" "$ROOT/src/rendering" "$ROOT/src/terminal" "$ROOT/src/events" "$ROOT/src/app" "$ROOT/src/controls" "$ROOT/src/layouts" "$ROOT/src/appearance" -name '*.pas' -print0)

if [[ "$FAILED" -ne 0 ]]; then
  echo "Portable units contain platform console dependencies." >&2
  exit 1
fi

echo "Portable isolation check passed."
