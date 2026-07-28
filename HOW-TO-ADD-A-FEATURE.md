# How a feature gets added to Teachy

Codified from the features actually shipped in this codebase — guided key setup,
telemetry, the progress store fixes — not invented in the abstract. Follow it and
you will land in the right layer with the right tests and without breaking
something load-bearing.

## 0. Find out what already exists — three tools, three questions

| Question | Tool |
|---|---|
| "Why is it like this?" | `gbrain search "<question>"` — semantic, over decisions and incidents |
| "Where does this live, what touches it?" | `graphify explain "<thing>" --graph ../graph/teachy-graph.json` |
| "Is this already known-broken?" | `teachy-brain/engineering/known-issues.md` |

Do this first, always. Several things in this codebase look wrong and are
load-bearing — `Teachy.Engine` is bypassed by the coaching path but still
project-referenced for `GridGeometry`, so deleting it breaks the build.

## 1. Decide which layer it belongs in

The Windows app is three processes. Picking wrong means rewriting it.

| It needs... | It goes in |
|---|---|
| UI, prompts, model calls, course logic, parsing | **Renderer** (`desktop/src/`) — all AI logic lives here |
| Window behaviour, tray, IPC, clipboard, file writes | **Electron main** (`desktop/electron/`) |
| UI Automation, global hotkeys, DPAPI, SAPI speech, screen capture | **C# sidecar** (`windows/Teachy.Sidecar/`) |

The rule: **the sidecar is OS primitives only.** If it can be done in
TypeScript, it belongs in the renderer. Adding AI logic to C# recreates the
three-language duplication that decision 0003 is about.

Anything crossing the boundary needs: a command in `Program.cs`'s switch, a
passthrough in `preload.cjs`, and a type in `types/global.d.ts`.

## 2. If it touches course content

Course data is transcribed from Swift — `leanring-buddy/ClickyCourse.swift` is
the source of truth, **not** `Teachy.Engine/CourseDefinitions.cs`, which was
never updated for the "Make a Website" rewrite. Transcribe from Swift, and
update `courseCatalog.ts` and `courseGoals.ts` together.

Content drift is a correctness bug here and is tested like one — see
`courseData.test.ts`.

## 3. If it can fail in front of a learner

Two hard rules, both learned from shipping the wrong thing:

- **Never put a raw error in the coach line.** It is displayed *and spoken
  aloud*. Route every failure through `describeFailureForLearner()`.
- **Never leave `isBusy` true on an early return.** The panel sticks on
  "Checking your screen…" with no way out.

## 4. If it should be measured

`recordEvent('name', {...})` from `state/telemetry.ts`. Only allow-listed
primitive fields survive the sink — that is deliberate, and adding a field means
adding it to `ALLOWED_EVENT_FIELDS` in `electron/telemetry.cjs` with a reason.

Never log screen content, prompts, model replies, learner speech, or keys. The
sink drops them, but do not rely on that as a licence to be careless.

## 5. Test it at the layer that can actually catch the bug

| Layer | Where | Catches |
|---|---|---|
| Pure logic | `src/**/*.test.ts` | parsing, mapping, data integrity |
| Sidecar protocol | `tests/sidecarProtocol.test.ts` | the whole IPC chain — boots the real sidecar |
| C# | `windows/Teachy.Platform.Tests/` | storage, native races |

The sidecar protocol tests are read-only by design: `click`/`type`/`press`
synthesise real input on whoever runs the suite, and `speak` talks out loud.

## 6. Verify, for real

```bash
cd teachy-app/desktop && npm run verify
```

Stops any running app, builds the sidecar, runs the C# tests, typechecks, runs
the TS tests, builds the renderer. **Run the thing you built, too.** In this
codebase, running-rather-than-assuming caught: a hard quit firing no abandonment
event, a `Join-Path` form that only exists in PowerShell 7, and non-ASCII
breaking the 5.1 parser. None of those were visible by reading.

## 7. Write back what you decided

If you made a real call:

```bash
pwsh ../teachy-brain/scripts/new-decision.ps1 "<the call>"
```

Fill in every section including **What it costs us**. Then commit — the graph and
gbrain index rebuild themselves on the hook.

See [WRITE-BACK.md](WRITE-BACK.md) for when *not* to record.

## The shortest version

```
gbrain search  ->  graphify explain  ->  known-issues
   -> pick the layer (sidecar = OS primitives only)
   -> build it
   -> humanise failures, never leak raw errors
   -> test at the layer that catches it
   -> npm run verify, and run the app
   -> new-decision.ps1 if you made a call
```
