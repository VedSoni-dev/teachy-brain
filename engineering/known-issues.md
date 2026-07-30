# Known issues

Open, honest, and ranked by what actually costs a learner something. Updated
2026-07-28 (post workspace split + known-issues slice).

## Open

### Windows learner model is only a first slice — P1, large

The sidecar now persists `skillNodes` + `portfolio` alongside course progress
(`windows-learner.json`, `get-learner-model`), and Skills/Portfolio prefer those
records. That is the unblock named below — not TeachyEngine parity.

Still missing on Windows: spaced repetition, teach-back scoring, autonomy
transfer, temporal continuity / streak, and real per-skill evidence (nodes are
still leveled from goal counts until teach-backs write richer events).

### No full Windows onboarding choreography — P1

Key setup's done step now names push-to-talk and mic/screen consent. There is
still no macOS-style `PermissionChoreographyView` or product tour. Windows needs
its own consent framing beyond a tip list.

### `Teachy.Engine` is a maintenance trap — P2

Bypassed by the coaching path but still project-referenced for `GridGeometry`, so
it cannot simply be deleted. See
[0003](../decisions/0003-windows-is-electron-plus-a-csharp-sidecar.md) for the two
ways out.

### electron-builder pulls a vulnerable `tar` — P2, dev-only

17 high advisories remain via `electron-builder-squirrel-windows`. npm's only
"fix" is downgrading electron-builder to 25, which is worse. We target nsis, not
squirrel, so the vulnerable path is unused. Dev-only surface — it is packaging,
never shipped code.

### Quitting mid-setup is derived, not measured — P2

Killing the app during key setup fires no abandonment event: the React unmount
handler never runs on a hard quit. Verified by doing it. The report derives quits
as shown minus completed minus dismissed, which is honest but coarse — it cannot
say which step a quitter was on, only the furthest step of the most recent
attempt. A main-process `before-quit` handler that records the last known setup
step would fix it. See [0008](../decisions/0008-telemetry-is-local-first.md).

### Nothing surfaces telemetry automatically — P2

`telemetry-report.ps1` has to be run by hand. It is not in `brain-status.ps1` and
no hook prints it, so the brain will hold an ungraded claim indefinitely while
the answer sits in a log file nobody opened.

### Old repo still serves appcast (and only that must stay) — P1

`VedSoni-dev/teachy` remains live infrastructure for Sparkle:

| Dependency | Status |
|---|---|
| `appcast.xml` (Sparkle auto-update) | **Must stay** — baked into shipped v1.0/v1.1 binaries |
| Site download buttons | Cut over to `teachy-releases` DMG |
| Academy registry / installURL | Cut over to public `teachy-releases` (teachy-app raw URLs 404 — private) |
| Mac `ClickyAcademyCatalog` defaults | Cut over to `teachy-releases` registry + Vercel site |
| Live site | Vercel `teachy-ashy-two.vercel.app` ← **teachy-web**; old `teachy-ashy.vercel.app` still on VedSoni-dev/teachy |
| `feature/learner-brain` | Rescued onto `teachy-app` branch `feature/learner-brain` |

**Deleting that repo is not safe and never will be.** End state: frozen-but-serving
`appcast.xml` (and historical release assets), nothing else.

### Cross-repo course URLs go stale silently — P2

`registry.json` installs courses by raw URL from `teachy-releases`. If that URL
points at the wrong repo or branch, the app installs an old course and
**nothing errors**. See [0005](../decisions/0005-three-repos.md).

### ACP subscription path is unverified against a signed-in account — P1

[0015](../decisions/0015-borrow-a-subscription-over-acp.md) shipped without ever
seeing a successful answer from a real subscription. This machine has both CLIs
installed and **logged out**, and signing in on the user's behalf was not an
option, so the verified surface stops at the auth boundary:

| Verified | How |
|----------|-----|
| Login-shell PATH discovery | Found `claude` in `~/.local/bin`, node in `/opt/homebrew/bin` |
| Status probe distinguishes all four states | Reported `adapterMissing` correctly on this machine |
| Handshake against the real adapter | `initialize` + capability negotiation, images=true |
| Logged-out → typed `authenticationRequired` | Real `-32000` from claude-agent-acp 0.63.0 |
| Streaming, thought-exclusion, permission rejection, mode pinning, cwd containment | Mock ACP agent; 6/6 checks + observed `mode=default permission=reject_always` |

The Electron implementation clears the same bar plus a real test suite:
`npm run verify` passes (typecheck, 161 tests across 16 files for the engine, plus
each edition's own), and a Node harness drives the actual `main/acp/*` modules
through a mock agent
(`mode=default permission=reject_always image=true`), a simulated internal
company agent loaded from a custom harness file, and the real adapter.

**Not verified anywhere:** a real turn returning real text, chunk cadence from a
live model, behaviour under rate limits or an expired session, and Codex
end-to-end (only its handshake was exercised). First person with a logged-in CLI
should hit **Test connection** in Settings.

**Windows: now run, and it was broken — 2026-07-29.** The first real Windows run
found that the adapter could never install at all: `cmd /s` stripped the quote
off `C:\Program Files\nodejs\npm.cmd` and the learner got `'C:\Program' is not
recognized`. Full write-up:
[the quoting incident](incidents/2026-07-29-acp-adapter-install-quoting.md).

Verified on Windows since the fix, driving the app's own `locator.cjs` and
`connection.cjs` against a live Claude Max session:

| Verified on Windows | Result |
|---|---|
| Adapter install via the Settings button | `@agentclientprotocol/claude-agent-acp@0.63.0` installed |
| `.cmd` shim discovery and spawn | `C:\Users\vedan\.npm-global\claude-agent-acp.cmd` |
| Handshake | `protocolVersion 1`, `image:true`, `embeddedContext:true` |
| `session/new` + a real prompt | streamed chunks, `stopReason: end_turn` |

**Still unverified on Windows:** the PowerShell terminal handoff for vendor-CLI
install, the in-app sign-in card (this box was already logged in, so the OAuth
paste-the-code path never rendered), the `%LOCALAPPDATA%` scratch directory,
behaviour under rate limits or an expired session, and Codex end to end.

### teachy-b2b cannot build on its own — P2

It resolves `@teachy/core` through a `file:` link to `../teachy-app/packages/core`,
so a clone of teachy-b2b alone fails to install. `teachy-app` must be checked out
as a sibling. See [0017](../decisions/0017-one-engine-two-editions.md).

### A core change can break B2B without a teachy-app → B2B CI bridge — P2

Both editions run core's full suite locally, and teachy-b2b CI now checks out
public teachy-app as a sibling and runs `npm run verify`. Still missing: a
workflow **on teachy-app** that, on core changes, also runs B2B verify (needs a
token that can read the private repo). Until then, merging core without running
B2B locally can still ship a cross-repo break.

### B2B course has no teach-back prompts or author tips — P2

`ai-fluency-at-work` migrated to the current goal schema with `teachBackPrompt:
null` and `tips: []` on all five goals. Schema-valid and the code guards for it,
so nothing breaks — but the "I'm stuck" hint has no author tips to draw from and
no goal offers a soft teach-back. Content authoring, deliberately not invented by
an agent for a product being sold.

### npm `allow-scripts` blocks Electron's postinstall — P2

A fresh `npm install` in teachy-app or teachy-b2b can leave
`node_modules/electron/dist` empty when npm blocks install scripts. `npm run
verify` still passes (typecheck, tests and vite build need no Electron binary), so
the repo looks healthy right up until launch throws "Electron failed to install
correctly". Run `npm approve-scripts electron` after installing — see
`teachy-app/INTERN.md`.

## Fixed, kept because the reasoning is worth having

| Was | Why it mattered |
|-----|-----------------|
| ACP adapter could never install on Windows | A green suite and a passing test literally named "quotes the path so spaces survive" — the bug was in cmd.exe's parser, not our array, and no assertion about our own data could reach it. [Incident](incidents/2026-07-29-acp-adapter-install-quoting.md) |
| Monorepo split left three Windows paths one level short | `sidecar.cjs` and `sidecarProtocol.test.ts` still resolved `windows/` from the old `desktop/` depth; `startElectron.mjs` launched the npm workspace root instead of the edition that owns `main.cjs`; vitest globs were built with `path.join`, so backslashes matched nothing and `npm run verify` exited 1 with "No test files found" on Windows while passing on macOS |
| teachy-b2b/desktop never compiled | Three files imported `GOALS_BY_COURSE_ID` from a module still exporting `COURSE_GOALS_BY_ID`. Invisible until something ran `tsc`; [0016](../decisions/0016-b2b-desktop-had-never-been-built.md) |
| macOS permission problem looked like a crash | `getSources()` throws `Failed to get sources.` rather than returning an empty list, so the helpful message was written for a case macOS never produces — and Electron's internal wording reached the learner |
| Model list unverified / possibly invented IDs | Live check 2026-07-28: every curated ID exists on OpenRouter. Guarded by `desktop/src/state/openRouterModels.test.ts` against `/models` |
| Overlay primary-display only | Electron overlay now covers the virtual-screen union; cursor + point-at convert into that space with per-display scale |
| Key setup ended with no PTT / consent framing | Done step now lists Ctrl+Alt, mic/screen prompts, and Learn |
| Push-to-talk crashed the sidecar | [Full incident](incidents/2026-07-28-sidecar-accessviolation.md) |
| Raw error strings spoken to learners | The coach line is read aloud; Electron IPC wrappers and C# process names reached people's ears |
| A failed vision check counted as the learner getting it wrong | An OpenRouter outage was indistinguishable from a wrong answer, incremented their failure streak, and said "Not quite there yet" |
| Verification hung forever with no API key | Early return left `isBusy` true; the panel sat on "Checking your screen…" with no way out |
| A crash mid-write destroyed all progress | Non-atomic save + a process that really does crash natively |
| Replaying a finished course erased it | "1 of 5" overwrote "5 of 5" and the course left Portfolio |
| Corrupt progress deleted silently | Now quarantined to `.corrupt` and logged |
| Windows listed 3 courses that no longer existed | Content drift is a correctness bug; now tested |
