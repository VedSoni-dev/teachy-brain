# 0007 - The brain maintains itself

**Date:** 2026-07-28
**Status:** accepted
**Affects:** every repo, every session, anyone who ever asks "why is it like this"

## The question

[0006](0006-git-and-graphify-as-the-company-memory.md) chose markdown in git as
the store and graphify as the query layer. It solved **storage and retrieval** and
did nothing about **capture** - and capture is the part that actually fails.

The honest state after 0006 was: an excellent company memory that a human
maintains. Every decision record was hand-written. The graph was rebuilt by
someone remembering to. Nothing noticed when either stopped happening. That is not
an AI-native company brain; it is a well-organised wiki with a good habit attached,
and habits decay silently.

So: what has to be true for the brain to stay honest without anyone maintaining it?

## Decision

Automate everything except the judgement call, and make the judgement call cheap
and checked.

| Gap | Mechanism |
|-----|-----------|
| Graph goes stale | `post-commit` hook rebuilds it, detached, on every commit in every repo |
| Staleness invisible | `graph-status.ps1` compares each repo's HEAD against the SHAs the graph was built from |
| Brain rots quietly | `brain-status.ps1` - one exit code covering graph freshness, unfilled records, a drifted README index, and code shipping while the brain stays still |
| Decisions lost at session end | `new-decision.ps1` scaffolds the record; `WRITE-BACK.md` says when to write one; every repo's `CLAUDE.md` instructs agents to do it |
| Drift noticed too late | `pre-push` hook runs the health check and warns as work leaves the machine |

Hooks live in `teachy-brain/hooks/` and are shared via `core.hooksPath`, so they
are committed and reviewed rather than rotting untracked inside each `.git/hooks`
where they silently differ per machine and vanish on a fresh clone.

## Why

Three principles did the work.

**Automate the mechanical, instruct the judgemental.** A machine can tell whether
the graph matches HEAD. It cannot tell whether what just happened was a decision or
a keystroke - only whoever did the work knows that. So the graph is automated and
capture is instructed, rather than pretending either is the other.

**Warn, never block.** The `pre-push` hook does not gate. A hook that blocks a push
over documentation gets bypassed with `--no-verify` inside a week, and after that
it is *worse than nothing*: it still looks like a safety net while catching nothing.

**Never block the commit either.** A full rebuild takes about a minute. A commit
that stalls for a minute is a commit people stop making, so the rebuild is detached
with a lock file, and a failed spawn degrades to "graph stays stale and the checker
says so" - never to a silent wrong answer.

## What it costs us

**Capture is still convention.** An agent that ignores `CLAUDE.md` writes nothing,
and `brain-status.ps1` can only notice the *symptom* - lots of code landing while
the brain stays still. It cannot tell a genuinely undocumented decision from a week
of honest bug fixes, so its main signal is a heuristic with a threshold somebody
picked. This is the weakest link and it should be named as such rather than papered
over.

**The checks are all local.** Hooks and scripts run on whoever's machine did the
work. There is no CI enforcing any of it, so a contributor who never runs
`install-hooks.ps1` gets none of it and nothing tells them.

**Windows-only automation.** Every script is PowerShell. `bootstrap.sh` covers
macOS setup, but the hooks shell out to `pwsh`/`powershell` and quietly no-op
without it. A Mac-only contributor gets no rebuilds and no warnings.

**More moving parts to rot.** Six scripts and two hooks are themselves code that
can break - and did, twice, during this work: a `Join-Path` form that only exists in
PowerShell 7, and non-ASCII characters inside strings that Windows PowerShell 5.1
mis-parses. Both were caught by running them rather than assuming.

**Still no feedback from reality.** Every decision record states what we believed.
None is graded against what happened, because there is no telemetry. The brain
records intent, never outcome - it can be perfectly maintained and perfectly wrong.

## Revisit when

- `brain-status.ps1` goes red for a fortnight and nobody notices - the warning is
  too quiet, and it needs to move somewhere with attention.
- A second person or a Mac joins the work, at which point local-only enforcement
  stops being sufficient and this needs CI.
- Telemetry exists, at which point decision records should carry an outcome and the
  health check should flag beliefs that reality has contradicted.

## See also

- [WRITE-BACK.md](../WRITE-BACK.md) - when to record, and when not to
- [0006](0006-git-and-graphify-as-the-company-memory.md) - the store this builds on
- `scripts/brain-status.ps1`, `hooks/post-commit`, `hooks/pre-push`
