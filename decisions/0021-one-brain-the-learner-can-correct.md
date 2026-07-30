# 0021 — One brain the learner can correct, and Teachy reads ours

**Date:** 2026-07-30
**Status:** accepted
**Affects:** notch tabs, learner memory, companion system prompt

## The question

[0020](0020-learner-brain-and-build-rules.md) added a conversational brain but left
two problems it named itself: there was **no way for a learner to see or correct
it**, and it did not meet the memory that already existed. Portfolio and Skills
read the sidecar's course-derived learner-model; the new brain lived in durable
agent state. Two memories, two tabs, each showing half a picture, and neither able
to answer "what am I building right now".

## The decision

**One Brain tab, absorbing Portfolio and Skills.** Four sections — what you're
building, what you can do, what you use, what keeps catching you — merged from both
memories into one list.

The conversational brain wins on conflict: a skill the coach observed with evidence
beats one inferred from counting completed goals.

**Full edit and delete, plus forget-everything.** Teachy will be wrong about people,
and an uncorrectable wrong belief compounds every session. Editing is prominent
rather than buried.

**Deleting a course-derived row records a suppression** rather than pretending to
remove it. The sidecar owns and regenerates its portfolio and skill nodes, so
without that the row reappears on next launch and the delete button is a lie.
Course-derived rows are also marked non-editable in the UI, because offering an
Edit button for something the sidecar rewrites would be the same lie in a different
place.

**Storage stays local.** No accounts, no server, nothing leaves the machine —
consistent with everything else Teachy stores.

**Teachy now reads our dev brain.** The hard rules and anti-patterns from
`product/course-design.md` ship as `TEACHY_TEACHING_DOCTRINE` and ride in the soul
prompt, so coaching reflects what we actually decided (Teachy is the active
prompter; doing beats navigating; nothing counts as done with nothing on screen)
rather than generic tutoring instinct.

## What it costs us

- **The doctrine is a curated copy, not a live read.** teachy-brain is a separate
  repo and is not guaranteed present at build time. When the hard rules change
  there, `soul.ts` must change too — nothing enforces it, and drift will be silent.
- **Two tabs disappeared.** Anyone used to Portfolio or Skills has to relearn where
  their work went.
- **The merge is heuristic.** A conversational build and a course build are treated
  as the same thing when their titles match case-insensitively. Different wording
  for the same project will list twice.
- **Local-only means lost on a new machine.** No export yet, so a learner's build
  history does not travel with them.
- **Still unverified: whether the coach actually writes to the brain.** The parsing,
  merging, editing and caps are covered by 38 tests, but nobody has watched a live
  turn emit a `[REMEMBER:]` tag. Carried forward from 0020.

## When to revisit

Add an export once anyone has real history worth losing — that is also the
lowest-cost path to a shareable portfolio artifact without building accounts.

If the doctrine drifts from `course-design.md` even once, generate it at build time
instead of copying it.
