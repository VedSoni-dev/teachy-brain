# 0022 — The soul is an OpenClaw-style workspace, with a bootstrap and an anti-nag heartbeat

**Date:** 2026-07-30
**Status:** accepted
**Affects:** `soul.ts`, `agentMemory.ts`, companion loop, heartbeat, `product/course-design.md`

## The question

[0013](0013-teachy-agent-runtime.md) committed Teachy to an OpenClaw-grade agent
runtime, but the harness that dictates behavior was one prose blob: `TEACHY_SOUL`
mixed identity, values, voice, hard rules, memory duties and the heartbeat
protocol in a single string, with more rules living inline in `companion.ts`.
Two OpenClaw layers were missing outright: there was **no first-session ritual**
(a brand-new learner got coached like a stranger mid-conversation), and the
heartbeat could **nudge every 4 minutes forever** over the same stretch of
silence — nothing stopped it but the model's own judgment.

## The decision

**1. The soul is now a workspace, one named section per OpenClaw concern**, all
in `soul.ts`, composed only by `buildSoulPromptSection`:

| Section | OpenClaw analog | Rides |
|---------|-----------------|-------|
| `TEACHY_IDENTITY` | IDENTITY | always |
| `TEACHY_SOUL` (values + voice) | SOUL | always |
| `TEACHY_BEHAVIOR` (hands boundary, think-first, memory duty) | AGENTS | always |
| `TEACHY_HEARTBEAT` (contract incl. one-nudge rule) | HEARTBEAT | always |
| `TEACHY_BOOTSTRAP` (first-session ritual) | BOOTSTRAP | first session only |
| `TEACHY_TEACHING_DOCTRINE` | — | always |

USER, TOOLS and MEMORY stay data, not prose: the learner brain, the stack
registry, and durable agent state already are those files.

**2. First session = empty conversation + empty memory log + empty brain.**
Then, and only then, BOOTSTRAP tells Teachy to introduce itself, interview one
question at a time, seed the brain with `[REMEMBER:]` tags, and get a real move
made before the session ends.

**3. One nudge per stretch of silence, enforced in code.** The heartbeat tick
checks `heartbeatNudgeAlreadyStands(memoryLog)`: if the newest heartbeat entry
is a nudge and no real turn has landed since, the tick returns before capturing
the screen or spending a token. The soul states the same rule, but the guard no
longer depends on the model honoring it.

**4. The hands boundary is now precise.** "Never do it for them" and "doing
beats navigating" read as a contradiction. The line is: Teachy may point and
open a known app or site (navigation friction is Teachy's job); it never clicks,
types, pastes, or submits inside the learner's work. `course-design.md` still
said "Teachy … pastes" and `toolPolicy: canDoForThem` from before
[0014](0014-teachy-shows-never-acts.md) — the source doctrine was stale against
a later decision, exactly the drift direction [0021](0021-one-brain-the-learner-can-correct.md)
did not predict. Fixed the source; the curated copy in `soul.ts` matches.

## What it costs us

- **The prompt got longer.** Six sections ride on every turn beside a
  screenshot. Bootstrap is gated, but identity/soul/behavior/heartbeat/doctrine
  are always on; if answers degrade on small models, the doctrine section is the
  first candidate to gate.
- **First-session detection is heuristic.** A learner who wipes their brain via
  forget-everything looks brand new and gets re-introduced to someone they
  already know. Arguably correct, still odd.
- **The one-nudge guard can under-nudge.** A learner stuck for an hour hears
  exactly one nudge until they speak again. Silence was chosen over nagging;
  the opposite failure is now impossible.
- **Whether the model performs the bootstrap well is unverified** — same status
  as the `[REMEMBER:]` tags from 0020/0021: parsing and gating are tested,
  live behavior is not.

## When to revisit

- After the first real first-session run: if Teachy interviews like a form
  instead of a conversation, the BOOTSTRAP prose needs work, not the gating.
- If a stuck learner reports Teachy "went quiet", allow a second nudge after a
  long multiple of the heartbeat interval instead of never.
- Graph not rebuilt: no `pwsh` on this machine. Run
  `pwsh scripts/rebuild-graph.ps1` on the next Windows session.
