# The teaching engine — what we build, in order

The sequencing behind [decision 0024](../decisions/0024-the-teaching-engine-is-the-roadmap.md).
Why each phase exists and what has to be true before the next one starts. *How*
the code works belongs in teachy-app; this is the order and the reasoning.

## The one sentence

> Teachy is the only tutor that can watch you do it, ask you to explain it, and
> then **refuse to help you the second time.**

Every phase below is either making that refusal possible, making it *earned*, or
keeping the app alive long enough for anyone to see it.

---

## Phase 0 — Rails

Decisions [0023](../decisions/0023-teachy-owns-no-window-model.md) and
[0024](../decisions/0024-the-teaching-engine-is-the-roadmap.md), plus the
`engineering/architecture.md` rewrite — it described the wiped Swift tree, so
anyone onboarding was reading a map of a deleted codebase.

**Done when** the brain describes the Electron world and the four-tab budget is
written down. Cheap, and it is what stops the sprawl.

---

## Phase 1 — Cold start, or none of this matters

The P1s already sitting in `engineering/known-issues.md`:

| Issue | Why it is fatal to the rollout |
|---|---|
| **ACP never verified against a signed-in account** | [0015](../decisions/0015-borrow-a-subscription-over-acp.md) shipped to the auth boundary and stopped. The borrowed-subscription path is what makes Teachy free to a student with no API budget. |
| No Windows onboarding choreography | Key setup names push-to-talk and consent in a tip list. Mac has `PermissionChoreographyView`; Windows has prose. |
| **Stale course installs silently** | `registry.json` resolves a raw URL. Wrong branch → the learner is taught an old course and *nothing errors*. |
| Mid-setup quits are derived, not measured | We cannot say which step loses people, only the furthest step reached. |

The third one is the worst kind of bug: a first session that quietly teaches the
wrong thing is worse than one that crashes.

**Gate:** a machine that has never run Teachy gets to a completed first goal
without the author present. Until that holds, everything below is theory.

---

## Phase 2 — Grade the teach-back

**Highest leverage change in the repo.** Today `useCourseSession.ts:426` asks the
teach-back question, the learner answers out loud, and the answer is discarded.

Score the transcript against the goal's `concepts` and `commonMistakes` from
`teachingContext` (already authored, already unused for this):

- **correct** → evidence toward promotion
- **partial** → re-coach the thin part, do not advance the ladder
- **misconception** → write a `MistakeRecord` (`learnerBrain.ts:59`, already
  exists) naming *the specific wrong idea*

That last branch is the whole point. It turns remediation from `remediationGoalID`
— a static jump authored months ago — into something aimed at the wrong model in
*this* person's head. It is the difference between "clicked the right button" and
"understands", and it is roughly 200 lines against machinery already built.

**Gate:** a deliberately wrong teach-back produces a `MistakeRecord` a human would
agree with, and the learner can correct it ([0021](../decisions/0021-one-brain-the-learner-can-correct.md)).

---

## Phase 3 — The evidence ladder

`SkillLevel = 'new' | 'guided' | 'independent'` is declared at `learnerBrain.ts:38`
and nothing promotes through it on evidence. Give each rung a gate:

| Rung | Evidence | Source |
|---|---|---|
| did it | vision pass | `courseVerifier` — built |
| can explain it | teach-back scored correct | phase 2 |
| can do it alone | same skill, **beacon withheld** | phase 4 |
| still can | recall on real work later | phase 5 |

Demotion has to be as real as promotion, or the ladder becomes a participation
trophy that lies to the learner and to us.

**Gate:** two learners with identical `completedGoals` counts can hold different
skill levels, and the difference is defensible from the event log.

---

## Phase 4 — Scaffolding fade

The hero moment, and the only phase a competitor cannot copy without owning the
screen.

- **First** encounter with a skill: the beacon points, as today.
- **Second:** it holds for a beat before moving. Stuck → it moves.
- **Third:** it does not move. *"You've done this one."* Silence is the teaching.

Unassisted success promotes to `independent`. Stalling brings the beacon back and
drops the rung. This is scaffolding fade / expertise reversal — real pedagogy,
not a gimmick — and it is only possible because Teachy physically owns the hint
channel per [0014](../decisions/0014-teachy-shows-never-acts.md).

**It needs an escape from day one.** *Want the pointer anyway?* A tutor that
silently stops helping is indistinguishable from a broken one, and 0024 names
this as the likeliest source of quits.

**Gate:** a learner who hits the fade and gets it unassisted says it felt like
being trusted, not abandoned. If that reads wrong in the first cohort, widen the
escape before touching thresholds.

---

## Phase 5 — Recall on real work

SM-2 is a trivial file; the scheduling is not the interesting part. What is
uniquely Teachy: **the review is not a flashcard, it is "open your project and do
that deploy again."** The screen is the card. Portfolio artifacts are the targets.

Depends on artifact capture, which the brain gestures at (`BuildProject`,
`learnerBrain.ts:22`) but does not yet fill from real sessions.

**Gate:** a scheduled review resolves against something the learner actually
built, not a question about it.

---

## Phase 6 — Authoring by demonstration

One course ships. Hand-writing goal graphs is the ceiling on "Teachy can teach
anything", and [0004](../decisions/0004-one-flagship-course.md) chose depth over
catalog partly because authoring is expensive.

So: **you do the thing on your screen once, Teachy watches, and drafts the goal
graph** — `goal` / `coachAsk` / `doneWhen` — which you then edit rather than
author. The capture and vision path already exist; the new part is a generator
constrained by `course-design.md` §6.4.

This is also the enterprise product in one sentence: *a company records its SOP
once and gets a course* — teachy-b2b's private curriculum without anyone writing
JSON.

**The known failure mode:** a screen recording is *literally* UI chrome, so the
generator will want to write "click the green Deploy button." §6.4 must be
enforced in the generator's prompt **and its tests**, not hoped for. Same drift
direction that caught 0021 and 0022.

**Gate:** a generated course survives the app it was recorded on being redesigned.

---

## What this order is betting

Reliability before depth before breadth — 0012's distribution × reliability ×
taste, applied. The bet loses if A&M asks for a catalog before the first cohort
finishes one path; in that case phase 6 moves up and phases 3–5 wait. That is a
product call, not an engineering one.
