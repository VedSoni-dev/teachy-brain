# Architecture, in one page

Two apps, one product. Both do the same thing: watch the learner's screen, coach
them out loud, point at the real control, and verify the goal is done.

## macOS — everything in-process

SwiftUI menu-bar app. ScreenCaptureKit for capture, a `CGEvent` tap for
push-to-talk, `NSSpeechSynthesizer` for voice, Keychain-ish storage. The notch
panel hosts Learn / Progress / Portfolio / Skills / Settings.

`TeachyEngine/` is the real one: `LearnerModel`, `SkillGraph`,
`VerificationEngine`, `TeachBackEngine`, `SpacedRepetitionEngine`,
`PortfolioManager`. This is the depth the product is actually about, and it is
the thing Windows does not have.

## Windows — three processes

See [decision 0003](../decisions/0003-windows-is-electron-plus-a-csharp-sidecar.md).

```
Electron main ──┬── notch window   (the panel, the single companion loop)
                └── overlay window (trailing cursor, bubble, pointing arc)
       │
       │ newline-delimited JSON over stdio
       ▼
  Teachy.Sidecar.exe (C#)
       UI Automation · global PTT hook · DPAPI · SAPI speech
       screen capture with the model-facing grid · progress store
```

**All AI logic lives in the renderer.** The sidecar is OS primitives only.

### One coaching turn

```
hold Ctrl+Alt
  -> C# transcribes
  -> transcript event to renderer
  -> capture-screen (C#)
  -> renderer calls OpenRouter with the screenshot
  -> reply streamed, [POINT:...] parsed out
  -> speak (C#) + overlay points at the target
```

### The pointing contract

The screenshot carries an invisible 24x16 grid (columns A–X, rows 1–16). The
model returns at most one tag:

- `[POINT:ax:7:label]` — a UI Automation element. Exact bounds, so this wins.
- `[POINT:M7:label]` — a grid cell.
- `[POINT:842,310:label]` — raw pixels.
- `[POINT:none]` — nothing worth pointing at.

Priority is ax > grid > pixel. The tag is stripped before the text is spoken —
an unstripped tag gets read aloud, which sounds broken. This is the one model
output the app acts on **physically**, moving a cursor on a real screen, so it is
the most heavily tested thing in the codebase.

## Where state lives

| What | Where |
|------|-------|
| API key | DPAPI-encrypted, sidecar-owned (Windows) |
| Learner progress | `~/.teachy/windows-learner.json`, atomic writes |
| Config | `~/.teachy/config-windows.json` |
| Courses | bundled in the app; installable ones in `~/.teachy/courses/` |
| Everything else | nowhere — there is no server |

`TEACHY_HOME` overrides the root, for portable installs and tests.

## The parity gap, stated plainly

Windows has the coaching loop and none of the learner model. Skills and Portfolio
are faked from a `completedGoals` count. There is no spaced repetition, no
teach-back scoring, no autonomy transfer, no onboarding beyond key setup, and the
overlay is primary-display only.

That gap is the roadmap. Full assessment lives at
`teachy-app/desktop/docs/ASSESSMENT.md`.

## Verification

One command, in `teachy-app/desktop`:

```bash
npm run verify
```

Stops any running app, builds the C# sidecar, runs the C# tests, typechecks,
runs the TypeScript tests, builds the renderer.
