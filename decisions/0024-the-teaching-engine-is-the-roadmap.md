# 0024 — The coaching loop is built; the teaching engine is the roadmap

**Date:** 2026-07-30
**Status:** accepted
**Affects:** `packages/core/src/state/*`, `courseVerifier.ts`, `learnerBrain.ts`, `useCourseSession.ts`, course authoring, `engineering/architecture.md`

## The surprising part, first

`engineering/architecture.md` said, in our own words:

> `TeachyEngine/` is the real one: `LearnerModel`, `SkillGraph`,
> `VerificationEngine`, `TeachBackEngine`, `SpacedRepetitionEngine`,
> `PortfolioManager`. **This is the depth the product is actually about**, and it
> is the thing Windows does not have.

Then [0011](0011-mac-ships-electron-react.md) moved Mac onto the Electron shell
and [0018](0018-b2b-proprietary-publish-wipe-swift.md) wiped Swift.
`find . -name "*.swift"` in teachy-app now returns nothing.

So that paragraph described a codebase that no longer exists, and **the Windows
parity gap quietly became the product gap** — with no record saying so. An intern
or agent reading `architecture.md` would have gone looking for an engine that was
deleted. Fixed in the same pass as this record.

## Where the shipping tree actually stands

`packages/core/src` is ~6,700 lines. It **has** the coaching loop:

| Built | Where |
|---|---|
| Companion loop + pointing contract | `useCompanionLoop.ts`, `companion.ts` |
| Goal verification, one vision pass → pass/partial/offTrack | `courseVerifier.ts` (132 lines) |
| Learner brain: projects, skills, tools, mistakes, `[REMEMBER:]` | `learnerBrain.ts` |
| Agent runtime: think, plan, memory, heartbeat | `agentThink/Plan/Memory.ts` ([0013](0013-teachy-agent-runtime.md)) |
| Borrowed subscriptions | `acpClient.ts` ([0015](0015-borrow-a-subscription-over-acp.md)) |

It does **not** have:

- **Teach-back scoring.** The question is asked and the answer is never read —
  `handleVoiceTeachBackAnswer` in `useCourseSession.ts:426` advances regardless.
- **An evidence-gated skill ladder.** `SkillLevel = 'new' | 'guided' |
  'independent'` is declared at `learnerBrain.ts:38` and nothing promotes through
  it on evidence.
- Skill graph / prerequisites / transfer, autonomy transfer, spaced repetition,
  portfolio artifact capture, verification depths.

One course ships: `courses/build-a-website.json`.

## The decision

**The product thesis, in one sentence, and it goes at the top of the brain:**

> Teachy is the only tutor that can watch you do it, ask you to explain it, and
> then **refuse to help you the second time.**

Withholding the beacon is the moat. It is possible only because Teachy physically
owns the hint channel — a video cannot do it, and neither can a chat window.
Everything else on the roadmap exists to make that refusal *earned* rather than
arbitrary.

Build order, sequenced in [`product/teaching-engine.md`](../product/teaching-engine.md):

0. Rails — this record, 0023, and the `architecture.md` fix
1. **Cold start** — the P1s in `known-issues.md`, ACP first
2. **Grade the teach-back** — a misconception becomes a `MistakeRecord`
3. **The evidence ladder** — did it → can explain it → can do it alone → still can
4. **Scaffolding fade** — the beacon withholds itself on known skills
5. **Recall on real work** — the screen is the flashcard, not a card
6. **Authoring by demonstration** — do it once, Teachy drafts the goal graph

## Why

- `company/what-teachy-is.md` already states the bet: *content is fuel, the engine
  is the moat*. The engine is the part that is missing, so it is the roadmap.
- Racing OpenClaw on feature count is the losing game named in
  [0023](0023-teachy-owns-no-window-model.md). Depth on the teaching loop is a
  race nobody else is running.
- Order follows 0012's distribution × reliability × taste. Phase 1 is boring and
  it gates everything.
- Phase 6 is the honest answer to "can Teachy teach entire courses." Hand-writing
  goal graphs is the ceiling today; one course has shipped since
  [0004](0004-one-flagship-course.md). It is also the B2B product in a sentence —
  a company records an SOP once and gets a course.

## What it costs us

- **Phase 1 is unglamorous and it gates the fun work.** If scaffolding fade jumps
  the queue because it demos well, we demo beautifully to 500 people whose ACP
  sign-in never worked. That failure is currently the likeliest one.
- **Scaffolding fade will read as hostile to some learners.** "The tutor stopped
  helping me" is a support complaint waiting to happen. It needs an explicit
  escape — *you've done this one; want the pointer anyway?* — or it becomes the
  reason people quit.
- **Grading a teach-back means judging understanding from a voice transcript with
  a model.** It will be wrong, and wrong in the expensive direction: demoting a
  skill someone actually has. It needs the learner-visible correction path from
  [0021](0021-one-brain-the-learner-can-correct.md) extended to the ladder.
- **Authoring by demonstration drifts toward encoding UI chrome**, because a
  screen recording literally is UI chrome. `product/course-design.md` §6.4 has to
  be enforced *inside the generator's prompt and its tests*, not hoped for. This
  is the same drift direction 0021 and 0022 both got caught by.
- **We are choosing depth over catalog with exactly one course live.** If A&M asks
  for breadth first, this order is wrong and phase 6 has to move up.
- Phases 2–5 all write to the learner brain, so the brain schema will churn while
  learners already have files on disk. Migration is now a real concern.

## When to revisit

- After the first A&M cohort: if learners quit at the **fade** rather than at key
  setup, phase 4 is too aggressive — widen the escape before tuning thresholds.
- If teach-back grading disagrees with `courseVerifier` often (vision says done,
  grader says misconception), one of them is wrong and the ladder should not
  promote until we know which.
- If phase 6 drafts goal graphs that name buttons, stop shipping generated courses
  and fix the constraint — a stale course installs silently today
  ([0005](0005-three-repos.md)), and a wrong generated one would too.
