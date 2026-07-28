# 0004 — One flagship course, not a catalog

**Date:** 2026-07-28
**Status:** accepted
**Affects:** product scope, teachy-app course data, the Academy registry

## Decision

Teachy ships exactly one bundled course: **Make a Website** — plan in ChatGPT,
build in Replit or a coding agent, ship live on Vercel.

Cut: Code with AI, Build a Phone Agent, AI Fluency Essentials.

## Why

Four half-courses teach nobody anything. The one thing that makes a person tell
someone else about Teachy is finishing something real, and "a link you can text
your mum" is the shortest honest path to that. A catalog invites browsing;
a single flagship invites finishing.

The flagship is also where the coaching model gets proven. If Teachy cannot walk
a stranger from nothing to a live URL, more courses will not fix that.

## What the course actually does differently

It runs the interview normies skip. Rather than accepting "make me a website", the
coach asks one question at a time, **writes the ChatGPT prompt for them**, opens
chatgpt.com and pastes it in the same turn. The learner reacts and decides; they
never hunt a link or retype a prompt.

Build tool follows from intake, not from a default:

| They pay for | They build in |
|---|---|
| Cursor | Cursor |
| Claude | Claude Code |
| ChatGPT | Codex / ChatGPT |
| nothing | Codex free tier |
| willing to pay | Claude Code |
| "just vibe" | Replit |

Hosting is Vercel, always `*.vercel.app` first. Never GitHub Pages. Custom
domains only after the vercel.app link works — the first win must not be blocked
on DNS.

## What it costs us

One course means one audience. Anyone who does not want a website bounces with
nothing to switch to, and there is no second thing to recommend when the flagship
does not land for someone. The catalog was thin, but it was at least a set of
doors.

It also concentrates all the risk: if "Make a Website" does not convert, there is
no other data point to learn from, and no way to tell whether the problem is the
coaching model or that one topic.

And the cut itself shipped a bug. Course data is hand-transcribed from Swift into
TypeScript, so cutting the catalog on macOS did **not** cut it on Windows. Windows
kept listing four courses, three of which no longer existed upstream, and coached
the abandoned GitHub Pages flow. Nothing failed loudly; it just taught the wrong
thing.

There are now tests asserting that every listed course has goals and that no
orphan goal sets survive a catalog cut. Content drift is a correctness bug and is
tested like one.

## Revisit when

The flagship has real completion data. A course nobody finishes is not a focus
problem, and a course people finish and share is the argument for building the
second one.

Completion, per-goal drop-off, and how often a "failure" was really our vision
check falling over are now counted — run `telemetry-report.ps1`
([0008](0008-telemetry-is-local-first.md)).

## See also

- `teachy-app/desktop/src/data/courseCatalog.ts`
- `teachy-app/desktop/src/data/courseGoals.ts`
- `teachy-app/leanring-buddy/ClickyCourse.swift` — the source of truth
- [Course design](../product/course-design.md)

## Outcome

Not yet measured. The instrumentation exists ([0008](0008-telemetry-is-local-first.md));
what is missing is usage. Run `telemetry-report.ps1` once real people have run
Teachy, and replace this section with what actually happened.
