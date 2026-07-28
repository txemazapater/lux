# Building LUX

Requires Free Pascal Compiler 3.2.2 or later.

## Windows

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target all
powershell -ExecutionPolicy Bypass -File tools\test.ps1
powershell -ExecutionPolicy Bypass -File tools\test_windows.ps1
```

Targets for `tools\build.ps1`:

| Target | Output |
|--------|--------|
| `hello` | `bin\hello_lux.exe` |
| `tests` | `bin\lux_tests.exe` |
| `windows-demo` | `bin\windows_demo.exe` |
| `windows-tests` | `bin\lux_windows_tests.exe` |
| `all` | all of the above |

Optional: point at a specific compiler:

```powershell
$env:FPC = 'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe'
powershell -ExecutionPolicy Bypass -File tools\build.ps1 -Target hello
```

Run examples:

```powershell
.\bin\hello_lux.exe
.\bin\windows_demo.exe
```

`windows_demo` requires an interactive console (not a redirected pipe). It enables VT/UTF-8, renders two frames, and restores the console on exit.

Optional interactive Windows integration tests:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test_windows_integration.ps1
```

## Linux / macOS (portable only)

Windows platform units are not built on Unix hosts.

```bash
chmod +x tools/build.sh tools/test.sh tools/check_portable.sh
./tools/build.sh
./tools/test.sh
./bin/hello_lux
```

Optional:

```bash
FPC=/usr/bin/fpc ./tools/build.sh
```

## One-command portable test run

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
```

Unix:

```bash
./tools/test.sh
```

These scripts also run the portable isolation check (`tools/check_portable.*`) which fails if Win32/termios references appear under `src/core`, `src/rendering` or `src/terminal`.

## Manual FPC invocation

Portable:

```bash
fpc -Mobjfpc -Scghi -O1 -g -gl -vewnhibq \
  -Fusrc/core -Fusrc/terminal -Fusrc/rendering -FUbin/units -FEbin -obin/hello_lux \
  examples/hello/hello_lux.pas

fpc -Mobjfpc -Scghi -O1 -g -gl -vewnhibq \
  -Fusrc/core -Fusrc/terminal -Fusrc/rendering -Futests -FUbin/units -FEbin -obin/lux_tests \
  tests/lux_tests.pas
```

Windows-only:

```powershell
fpc -Mobjfpc -Scghi -O1 -g -gl -vewnhibq `
  -Fusrc/core -Fusrc/terminal -Fusrc/rendering -Fusrc/platform/windows -Futests `
  -FUbin/units -FEbin -obin/windows_demo.exe `
  examples/windows_demo/windows_demo.pas
```

## Compiler switches

The build scripts use:

| Switch | Purpose |
|--------|---------|
| `-Mobjfpc` | Object Pascal mode |
| `-Scghi` | C-like operators, label goto, inlining, allow `inline` |
| `-O1` | Basic optimizations |
| `-g` `-gl` | Debug info with line info |
| `-vewnhibq` | Show errors, warnings, notes, hints; hide specific noise; be quiet about logo |

Build products land under `bin/` and are ignored by Git.

## Continuous integration

GitHub Actions (`.github/workflows/ci.yml`) runs **Linux only**:

- portable isolation check
- build `hello_lux`
- portable unit tests
- smoke-run `hello_lux`

Windows compilation, `windows_demo`, and Windows platform tests are **not** run on GitHub-hosted runners (FPC install there is unreliable for this project). Validate those locally with `tools\build.ps1` / `tools\test_windows.ps1`.
