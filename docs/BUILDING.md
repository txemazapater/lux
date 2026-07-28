# Building LUX

Requires Free Pascal Compiler 3.2.2 or later.

## Windows

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
powershell -ExecutionPolicy Bypass -File tools\test.ps1
```

Optional: point at a specific compiler:

```powershell
$env:FPC = 'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe'
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Run the example:

```powershell
.\bin\hello_lux.exe
```

## Linux / macOS

```bash
chmod +x tools/build.sh tools/test.sh
./tools/build.sh
./tools/test.sh
./bin/hello_lux
```

Optional:

```bash
FPC=/usr/bin/fpc ./tools/build.sh
```

## One-command test run

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1
```

Unix:

```bash
./tools/test.sh
```

Both scripts compile `tests/lux_tests.pas` and execute it. A non-zero exit code means failures.

## Manual FPC invocation

```bash
fpc -Mobjfpc -Scghi -O1 -g -gl -vewnhibq \
  -Fusrc/core -Fusrc/rendering -FUbin/units -FEbin -obin/hello_lux \
  examples/hello/hello_lux.pas

fpc -Mobjfpc -Scghi -O1 -g -gl -vewnhibq \
  -Fusrc/core -Fusrc/rendering -Futests -FUbin/units -FEbin -obin/lux_tests \
  tests/lux_tests.pas
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

GitHub Actions workflow `.github/workflows/ci.yml` builds the example and runs the portable tests on Ubuntu and Windows.
