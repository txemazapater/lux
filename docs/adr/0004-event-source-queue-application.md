# ADR 0004: Event source, queue and application loop

## Status

Accepted — Phase 4.

## Context

Phase 4 needs normalized keyboard, mouse, resize and timer input on Windows and Unix, plus a portable main loop. Coupling `TLuxApplication` directly to console/`poll` APIs would force platform conditionals into the portable core and make synthetic events (quit, timers, future invalidations) awkward.

## Decision

1. **`Lux.Events`** defines the portable event model (`TLuxEvent`, keys vs Unicode characters, mouse, resize, timer, quit). No WinAPI, termios or ANSI types.
2. **`ILuxEventSource`** (`PollEvent` / `WaitEvent`) is the only way the application obtains terminal input. Semantics: Poll is non-blocking; Wait blocks until an event or timeout; timeout `< 0` means indefinite; events are always fully initialized.
3. **Platform event sources** (`TLuxUnixEventSource`, `TLuxWindowsEventSource`) implement the interface. Sessions configure raw/mouse/console modes; parsers/translators decode bytes or console records into `TLuxEvent`.
4. **`TLuxEventQueue`** is a portable FIFO for terminal events, timer firings and synthetic posts. Single-threaded in Phase 4.
5. **`TLuxTimerScheduler`** uses an injectable monotonic clock; the application wait timeout is the minimum of the next timer due time and any caller-requested wait.
6. **`TLuxApplication`** owns writer, source, queue, timers, surface and renderer. It contains no platform conditionals. It waits without busy-spinning, dispatches one event at a time on the `Run` thread, and repaints only after invalidation or resize.

## Consequences

- The same demo (`EventLoopDemo`) runs on Windows and Unix with only the platform factory program differing.
- Controls/widgets remain out of scope until Phase 5; the application exposes virtual `HandleEvent` / `Update` / `RenderContent` / `OnResize` only.
- Escape vs CSI ambiguity on Unix is resolved with a short documented timeout (`LuxUnixEscAmbiguityTimeoutMs = 50`) in the event source, not inside signal handlers.
- Key repeat counts are preserved on the event (`RepeatCount`); Unix normally uses `1`, Windows may pass the console counter without expanding into multiple events.
