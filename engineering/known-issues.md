# Known issues

Open, honest, and ranked by what actually costs a learner something. Updated
2026-07-28.

## Open

### The model list is unverified — P0, cheap to fix

`SettingsTab.tsx` offers `gemma-4-26b-a4b-it` and `claude-haiku-4.5`, among
others. Several of those IDs do not trace to any source and were, as far as
anyone can tell, invented. **If an ID does not exist on OpenRouter, picking it
breaks every request** with an error that reads like the learner's key is wrong.

Fix: check the list against OpenRouter's live `/models`, cut what is not real,
and prefer fetching it rather than hardcoding.

### Windows has no learner model — P1, large

There is no `TeachyEngine` on Windows. Skills and Portfolio are computed from a
`completedGoals` count, so they display something that looks like insight and is
not. No spaced repetition, no teach-back scoring, no autonomy transfer, no
temporal continuity.

This is the single biggest gap between the two apps and the thing that makes the
Mac version worth more. Unblocking it starts with extending the sidecar's
progress store toward a `LearnerModel` shape — that one change lights up Skills,
Portfolio and Progress together.

### Overlay is primary-display only — P1

`getPrimaryDisplay()` in `main.cjs`. Cursor polling and pointing break across
monitors. The macOS overlay is explicitly multi-monitor and joins all Spaces.
Anyone with two screens sees Teachy point at nothing.

### No onboarding beyond key setup — P1

Key setup exists now. Nothing explains push-to-talk, what Teachy can see, or why
it wants to. macOS has a `PermissionChoreographyView` and a product tour; Windows
has neither, and Windows also needs its own consent framing for microphone and
screen access.

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

### The old combined repo is still live infrastructure — P1

`VedSoni-dev/teachy` was called an archive in [0005](../decisions/0005-three-repos.md).
It is not. Five things still resolve against it:

| Dependency | What breaks |
|---|---|
| `appcast.xml` (Sparkle auto-update) | Every installed Mac copy checks this URL — **and it is compiled into shipped v1.0/v1.1 binaries**, so it can never be changed for those installs |
| `releases/latest` | The download button on 4+ pages of the live site |
| `gh-pages` branch | Serves `vedsoni-dev.github.io/teachy` |
| `registry.json` `installURL` | Course installs |
| `ClickyAcademyCatalog.swift` | The Mac app's academy catalog fetch |

It also holds `feature/learner-brain` — **3 commits that exist nowhere else**,
because the split cloned single-branch from `main`.

**Deleting that repo is not safe and never will be.** The appcast URL is baked
into binaries already on people's machines. The end state is frozen-but-serving,
not deleted.

Cutover order, when someone does it: rescue `feature/learner-brain` into
teachy-app; repoint `registry.json` and `ClickyAcademyCatalog.swift` at
teachy-app; move Vercel and `gh-pages` to teachy-web; update the site's download
links. After that it serves only `appcast.xml`.

### Cross-repo course URLs go stale silently — P2

`teachy-web`'s `registry.json` installs courses from the app repo by raw URL. If
that URL points at the wrong repo or branch, the app installs an old course and
**nothing errors**. See [0005](../decisions/0005-three-repos.md).

## Fixed, kept because the reasoning is worth having

| Was | Why it mattered |
|-----|-----------------|
| Push-to-talk crashed the sidecar | [Full incident](incidents/2026-07-28-sidecar-accessviolation.md) |
| Raw error strings spoken to learners | The coach line is read aloud; Electron IPC wrappers and C# process names reached people's ears |
| A failed vision check counted as the learner getting it wrong | An OpenRouter outage was indistinguishable from a wrong answer, incremented their failure streak, and said "Not quite there yet" |
| Verification hung forever with no API key | Early return left `isBusy` true; the panel sat on "Checking your screen…" with no way out |
| A crash mid-write destroyed all progress | Non-atomic save + a process that really does crash natively |
| Replaying a finished course erased it | "1 of 5" overwrote "5 of 5" and the course left Portfolio |
| Corrupt progress deleted silently | Now quarantined to `.corrupt` and logged |
| Windows listed 3 courses that no longer existed | Content drift is a correctness bug; now tested |
