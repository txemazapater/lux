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
| `controls-demo` | `bin\controls_demo_windows.exe` |
| `stack-demo` | `bin\stack_demo_windows.exe` |
| `cursor-demo` | `bin\cursor_demo_windows.exe` |
| `input-inspector` | `bin\input_inspector_windows.exe` |
| `all` | all of the above |

Run examples:

```powershell
.\bin\hello_lux.exe
.\bin\windows_demo.exe
.\bin\eventloop_windows.exe
.\bin\controls_demo_windows.exe
.\bin\stack_demo_windows.exe
.\bin\cursor_demo_windows.exe
.\bin\input_inspector_windows.exe
```

`windows_demo`, `eventloop_windows`, `controls_demo_windows`, `stack_demo_windows`, `cursor_demo_windows` and `input_inspector_windows` require an interactive console. Optional integration:

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
./bin/controls_demo_unix
./bin/stack_demo_unix
./bin/cursor_demo_unix
```

Targets for `tools/build.sh`:

| Target | Output |
|--------|--------|
| `hello` | `bin/hello_lux` |
| `tests` | `bin/lux_tests` |
| `unix-demo` | `bin/unix_demo` |
| `unix-tests` | `bin/lux_unix_tests` |
| `eventloop` | `bin/eventloop_unix` |
| `controls-demo` | `bin/controls_demo_unix` |
| `stack-demo` | `bin/stack_demo_unix` |
| `cursor-demo` | `bin/cursor_demo_unix` |
| `all` | all of the above |

`unix_demo`, `eventloop_unix`, `controls_demo_unix`, `stack_demo_unix` and `cursor_demo_unix` require a TTY. Optional integration:

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

Fails if Win32/termios references appear under `src/core`, `src/rendering`, `src/terminal`, `src/events`, `src/app` or `src/controls`.

## Continuous integration

GitHub Actions is **Linux-only**:

- portable isolation, build, portable tests
- Unix platform unit tests (includes offline input parser)
- build `unix_demo` / `eventloop_unix` / `controls_demo_unix` and smoke under a pseudo-TTY (`script`)
- smoke-run `hello_lux`

Windows validation remains a local developer workflow.
