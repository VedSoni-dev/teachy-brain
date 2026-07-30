# Architecture, in one page

**One engine, two editions, two OS hosts.** The engine watches the learner's
screen, coaches out loud, points at the real control, and verifies the goal is
done. There is no Swift app and no `desktop/` folder — see
[0011](../decisions/0011-mac-ships-electron-react.md) and
[0018](../decisions/0018-b2b-proprietary-publish-wipe-swift.md).

## The shape

```
teachy-app/
  packages/core/        @teachy/core — the engine (MIT)
    main/               Electron main: main.cjs, preload.cjs, edition.cjs,
                        telemetry.cjs, openApp.cjs, acp/
      macHost.cjs       macOS OS primitives, in-process
      sidecar.cjs       Windows bridge, newline-delimited JSON over stdio
    src/                renderer: studio/ tabs/ course/ overlay/ dock/
                        onboarding/ state/ data/ edition/
  apps/b2c/             free edition — courses, goals, branding (MIT)
  windows/              C# solution: Teachy.Sidecar, Teachy.Platform, Teachy.Engine
teachy-b2b/             workplace edition, file:-links ../teachy-app/packages/core
```

Editions supply content and policy through the `edition/` contract
([0017](../decisions/0017-one-engine-two-editions.md)); neither edition forks the
engine.

## The host boundary

**All AI logic lives in the renderer.** Both hosts expose the same command
surface, so the renderer never branches on OS:

| Host | How |
|---|---|
| macOS | `macHost.cjs` — in-process, no sidecar |
| Windows | `sidecar.cjs` → `Teachy.Sidecar.exe` (UI Automation, global PTT hook, DPAPI, SAPI speech) |

Commands: `capture-screen`, `inspect-elements`, `speak` / `stop-speaking`,
`get-`/`set-config`, `get-`/`set-api-key`, `get-`/`set-agent-state`,
`append-memory`, `get-progress`, `get-learner-model`, `record-goal-completed`,
`get-screen-info`, `open-url`, `quit`.

The hosts also expose `click-element`, `click-point`, `type-text`, `press-key`
and `scroll`. **These exist for navigation, not for doing the learner's work.**
Teachy may point and open a known app or site; it never clicks, types, pastes or
submits inside the learner's work — [0014](../decisions/0014-teachy-shows-never-acts.md),
sharpened by [0022](../decisions/0022-soul-as-an-openclaw-workspace.md). The
primitives being available is not permission to use them.

## One coaching turn

```
hold Ctrl+Alt (Win) / ctrl+option (Mac)
  -> host transcribes
  -> transcript event to renderer
  -> capture-screen (host)
  -> renderer calls the model with the screenshot
  -> reply streamed, [POINT:...] parsed out
  -> speak (host) + overlay points at the target
```

The model is reached via OpenRouter with the learner's own key
([0001](../decisions/0001-bring-your-own-key-not-a-hosted-proxy.md)) or a borrowed
Claude Pro / ChatGPT subscription over ACP
([0015](../decisions/0015-borrow-a-subscription-over-acp.md)).

## The pointing contract

The screenshot carries an invisible 24×16 grid (columns A–X, rows 1–16), defined
in `src/state/companion.ts`. The model returns at most one tag:

- `[POINT:ax:7:label]` — an accessibility / UI Automation element. Exact bounds, so this wins.
- `[POINT:M7:label]` — a grid cell.
- `[POINT:842,310:label]` — raw pixels.
- `[POINT:none]` — nothing worth pointing at.

Priority is ax > grid > pixel. The tag is stripped before the text is spoken — an
unstripped tag gets read aloud, which sounds broken. This is the one model output
the app acts on **physically**, moving a cursor on a real screen, so it is the
most heavily tested thing in the codebase.

## The prompt stack

The soul is a workspace of named sections declared in `src/data/soul.ts` and
composed by `buildSoulPromptSection` in `src/state/agentMemory.ts` — identity,
values/voice, behavior, heartbeat, teaching doctrine, plus a bootstrap section
that rides only on a first session
([0022](../decisions/0022-soul-as-an-openclaw-workspace.md)). The learner brain
and stack registry ride as data, not prose
([0020](../decisions/0020-learner-brain-and-build-rules.md),
[0021](../decisions/0021-one-brain-the-learner-can-correct.md)).

## Where state lives

| What | Where |
|------|-------|
| API key | DPAPI-encrypted and sidecar-owned (Windows); host-owned (Mac) |
| Learner progress | `~/.teachy/`, atomic writes — `windows-learner.json` on Windows |
| Agent state | `~/.teachy/` — path, plan, conversation, memory log |
| Config | `~/.teachy/` |
| Courses | bundled in the edition; installable ones in `~/.teachy/courses/` |
| Everything else | nowhere — there is no server |

`TEACHY_HOME` overrides the root, for portable installs and tests.

## The gap, stated plainly

The **coaching loop** is built. The **teaching engine** is not.

Missing from the shipping tree: teach-back scoring (the question is asked and the
answer discarded), an evidence-gated skill ladder (`SkillLevel` is declared and
nothing promotes through it), skill graph and transfer, autonomy transfer, spaced
repetition, portfolio artifact capture. Windows additionally lacks onboarding
choreography beyond key setup, and its overlay is primary-display only.

That gap is the roadmap: [0024](../decisions/0024-the-teaching-engine-is-the-roadmap.md)
and [`product/teaching-engine.md`](../product/teaching-engine.md). Ranked open
issues live in [`known-issues.md`](known-issues.md).

> Historical note: these modules existed in the Swift `TeachyEngine/`, which 0018
> wiped. This page described that tree until 2026-07-30. They were never ported.

## Verification

One command, in `teachy-app`:

```bash
npm run verify
```

Runs `verify` in `@teachy/core` then `@teachy/b2c` — typecheck, TypeScript tests,
renderer build. On Windows it also builds and tests the C# sidecar. `verify` can
pass without the Electron binary, so it is not proof the app boots: run
`npm run start`, and `npm approve-scripts electron` first on machines that block
install scripts.
