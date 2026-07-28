# 0003 — Windows is Electron plus a C# sidecar

**Date:** 2026-07-27
**Status:** accepted
**Affects:** teachy-app Windows architecture

## The question

macOS Teachy is a native SwiftUI app that does everything in-process:
ScreenCaptureKit for capture, a `CGEvent` tap for the hotkey, Keychain for
secrets, `NSSpeechSynthesizer` for voice. Windows needs the same capabilities.
What is the shape?

## Decision

Three processes:

| Layer | What it is | Why it exists |
|-------|-----------|---------------|
| **Electron main** | notch + overlay windows, tray, cursor polling | window management, always-on-top, click-through |
| **Renderer** | React. **All AI logic lives here** | one codebase for prompts, parsing, course runtime |
| **C# sidecar** | `Teachy.Sidecar.exe`, newline-JSON over stdio | UI Automation, the global low-level hook, DPAPI, SAPI |

The sidecar exists because Electron genuinely cannot do those four things. That
split is sound and is not the part to second-guess.

## The consequence nobody planned

Putting the AI logic in the renderer means the companion prompt, the point-tag
parser, grid geometry, the course verifier, the agent tool loop and the course
data now exist in **three languages**: Swift, C# (`Teachy.Engine`) and TypeScript.

`Teachy.Engine` was written to be the Windows brain and then bypassed. It is not
dead — `Teachy.Platform` project-references it for `GridGeometry`, so the sidecar
transitively depends on it and a blind delete breaks the build — but nothing in
the coaching path calls it. It sits in the tree as a maintenance trap: the kind
of code that looks authoritative and is not.

Course data proved the cost. `CourseDefinitions.cs` was never updated for the
"Make a Website" rewrite, so anyone re-transcribing from it would have shipped a
course the Mac abandoned. Windows course data is now transcribed **from Swift
directly**, cutting a three-hop chain to two.

## What is still owed

Pick one and commit:

- **(a)** Extract the still-used bits (grid geometry) out of `Teachy.Engine` into
  `Teachy.Platform`, drop the dangling `ProjectReference` in
  `Teachy.Sidecar.csproj`, delete Engine, and make TypeScript the Windows source
  of truth.
- **(b)** Route the renderer through the sidecar so C# is authoritative and the
  TypeScript is thin.

(a) is the smaller change and matches where the code already is. Either way it is
a Windows-toolchain task, not a text delete.

## What it costs us

The sidecar owns every OS capability, so **when it dies, the app is a shell** —
every command fails with "background service is not running" and the UI keeps
accepting clicks that go nowhere. That happened in the wild; see
[the incident](../engineering/incidents/2026-07-28-sidecar-accessviolation.md).
The bridge now supervises and restarts the child, which is a consequence of this
architecture that the original design did not account for.

## See also

- `teachy-app/desktop/electron/sidecar.cjs`
- `teachy-app/windows/Teachy.Sidecar/Program.cs`
- `teachy-app/desktop/docs/ASSESSMENT.md` — full parity assessment
