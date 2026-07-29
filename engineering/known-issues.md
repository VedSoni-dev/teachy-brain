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

## Fixed, kept because the reasoning is worth having

| Was | Why it mattered |
|-----|-----------------|
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
