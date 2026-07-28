{ Portable event source abstraction. }
unit Lux.EventSource;

{$mode objfpc}{$H+}

interface

uses
  Lux.Events;

type
  { Produces normalized TLuxEvent values without exposing platform APIs.

    PollEvent:
      Returns immediately. True means Event is fully initialized.
      False means no event was available; Event is set to ekNone.

    WaitEvent:
      Blocks until an event is available or TimeoutMs expires.
      TimeoutMs < 0 means wait indefinitely.
      TimeoutMs = 0 means a single non-blocking poll (same as PollEvent).
      TimeoutMs > 0 waits up to that many milliseconds.
      True means Event is fully initialized.
      False means timeout (or interrupted wait with no event); Event is ekNone.

    Implementations must never return partially initialized events. }
  ILuxEventSource = interface
    ['{B7C1D4E2-8A5F-4E91-9C3A-1F6D2E8B0A47}']
    function PollEvent(out Event: TLuxEvent): Boolean;
    function WaitEvent(out Event: TLuxEvent; TimeoutMs: Integer): Boolean;
  end;

implementation

end.
