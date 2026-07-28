# Push-to-talk killed the sidecar, and the app became a shell

**Date:** 2026-07-28
**Severity:** total loss of function, silent
**Found by:** using the app — no test or alert caught it

## What happened

A learner mid-course pressed "Do it for me" and got read this, out loud:

> I couldn't finish that automatically: Error invoking remote method
> 'sidecar:send': Error: Teachy background service is not running.

The sidecar had died. Every command after that failed the same way, forever. The
UI kept accepting clicks that went nowhere.

## Root cause

`MicrophoneRecorder.StopRecordingAndGetWavBytes()` ran teardown while holding
`recordingStateLock` — the same lock `HandleAudioDataAvailable` takes on NAudio's
record thread.

So on push-to-talk release:

1. The record thread raises `DataAvailable` and blocks on the lock.
2. The stopper, holding the lock, calls `StopRecording()` then `Dispose()`.
3. `Dispose()` frees the wave headers.
4. The record thread wakes, returns from the handler, and loops into
   `WaveInBuffer.Reuse()` → `waveInAddBuffer` on freed memory.

```
Fatal error. System.AccessViolationException
  at NAudio.Wave.WaveInterop.waveInAddBuffer(IntPtr, WaveHeader, Int32)
  at NAudio.Wave.WaveInBuffer.Reuse()
  at NAudio.Wave.WaveInEvent.DoRecording()
```

Exit `0xC0000005`. An `AccessViolationException` cannot be caught by .NET, so this
was always a whole-process kill, not a handled error.

## Why it was so damaging

Two independent faults stacked:

1. **The sidecar owns every OS capability** ([0003](../../decisions/0003-windows-is-electron-plus-a-csharp-sidecar.md)),
   so its death removes screen capture, speech, the key store and push-to-talk at
   once.
2. **Nothing restarted it, and nothing said so.** The bridge failed each command
   with a string and left the UI fully interactive. The app looked alive.

## Fixes

- **The race.** Detach device/writer/buffer under the lock, release it, *then*
  stop, wait for `RecordingStopped`, and only then dispose. 2s cap — past that,
  leak the device rather than dispose underneath it or hang the sidecar. The exit
  signal is captured by a per-session lambda, not read off a field, so a late
  callback from a previous session cannot signal the current one.
- **Supervision.** `sidecar.cjs` respawns the child on unexpected exit, bounded to
  3 crashes per 60s so a genuine fault surfaces instead of spinning.
- **The gap.** `send()` waits out a restart rather than failing instantly. Safe
  only because the command has not been written yet — requests already in flight
  stay rejected, since replaying `record-goal-completed` would double-count.
- **The words.** Raw errors are no longer spoken. See
  [known-issues](../known-issues.md) history and `failureMessages.ts`.

## Verification

A stress harness ran 40 start/stop rounds with holds straddling the 50ms buffer
tick; 11 rounds stopped with live `DataAvailable` callbacks in flight and none
faulted. Restart was verified by killing `Teachy.Sidecar.exe` under the running
app — it came back one second later.

## What this changed beyond the fix

Three lessons, all now enforced by tests:

1. **A test that only exercises the renderer cannot see this class of bug.**
   `tests/sidecarProtocol.test.ts` boots the real sidecar and speaks the real
   protocol.
2. **Internal error strings must never reach a learner**, because the coach line
   is spoken aloud. Every failure now maps to a plain sentence with a next step.
3. **A crash mid-write can destroy learner progress.** This crash is what made
   the non-atomic `LearnerProgressStore.Save()` a real risk rather than a
   theoretical one — it now writes to a temp file and swaps.
