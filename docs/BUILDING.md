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
| `eventloop` | `bin\eventloop_windows.exe` |
| `all` | all of the above |

Run examples:

```powershell
.\bin\hello_lux.exe
.\bin\windows_demo.exe
.\bin\eventloop_windows.exe
```

`windows_demo` and `eventloop_windows` require an interactive console. Optional integration:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test_windows_integration.ps1
```

## Linux

```bash
chmod +x tools/*.sh
./tools/build.sh all
./tools/test.sh
./tools/test_unix.sh
./bin/hello_lux
./bin/unix_demo
./bin/eventloop_unix
```

Targets for `tools/build.sh`:

| Target | Output |
|--------|--------|
| `hello` | `bin/hello_lux` |
| `tests` | `bin/lux_tests` |
| `unix-demo` | `bin/unix_demo` |
| `unix-tests` | `bin/lux_unix_tests` |
| `eventloop` | `bin/eventloop_unix` |
| `all` | all of the above |

`unix_demo` and `eventloop_unix` require a TTY. Optional integration:

```bash
./tools/test_unix_integration.sh
```

Windows platform units are not built on Unix hosts, and Unix units are not built on Windows hosts.

## Portable isolation

```powershell
powershell -ExecutionPolicy Bypass -File tools\check_portable.ps1
```

```bash
./tools/check_portable.sh
```

Fails if Win32/termios references appear under `src/core`, `src/rendering`, `src/terminal`, `src/events` or `src/app`.

## Continuous integration

GitHub Actions is **Linux-only**:

- portable isolation, build, portable tests
- Unix platform unit tests (includes offline input parser)
- build `unix_demo` / `eventloop_unix` and smoke under a pseudo-TTY (`script`)
- smoke-run `hello_lux`

Windows validation remains a local developer workflow.
