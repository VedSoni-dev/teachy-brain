# 0020 — A durable learner brain, and Teachy's own build rules

**Date:** 2026-07-30
**Status:** accepted
**Affects:** companion loop, system prompt, durable agent state

## The question

Teachy had two thin memories: skills and portfolio derived from course goal counts,
and a freeform memory log. Neither answered the question that decides whether a
tutor feels like the same tutor tomorrow — **what is this person building, and
where did they get stuck?**

Separately, tool choice was deterministic (`stackRegistry`) but *sequencing* was
not. Nothing stopped the coach saying "open Cursor" to someone who had not yet
decided what they were making.

## The decision

**1. A structured learner brain**, persisted with the existing durable agent state:

| Kind | Holds |
|------|-------|
| `projects` | what they're building, status, stack, artifact URL, last blocker |
| `skills` | area → `new` / `guided` / `independent`, plus the evidence |
| `tools` | `pays-for` / `uses` / `tried` / `avoided` |
| `mistakes` | pattern → fix, with a **count** |

Written by the coach emitting `[REMEMBER:<kind>: …]` tags in its reply, parsed and
stripped exactly like the existing `[POINT:…]` and `[THINK]…[/THINK]` tags. A
second extraction call per turn would double the cost of every interaction for
information the model already had in hand.

Riding on `get-agent-state` / `set-agent-state` means it works on both platforms
today, with no new sidecar command.

**2. `buildRules.json`** — Teachy's opinions as data, next to the tool registry:
principles, ordered `sequences` per goal (website / phone agent / coding agent),
and `antiPatterns`. Data rather than prose in the prompt for the same reason the
tool registry is data: a model reasoning from principles picks differently on
different days, and these are calls we want reviewable in a diff.

Only the *matched* sequence ships in full; the rest are omitted. Sending every path
on every turn crowds out the screenshot with guidance about something the learner
is not doing.

## Two bugs the tests caught before shipping

**A brain holding only mistakes reported itself empty.** The emptiness guard
checked projects, skills and tools but not mistakes — so a learner whose one
durable fact was a recurring snag looked brand new, and that snag is exactly what
was worth remembering.

**Longest-keyword matching routed the wrong path.** "Build a phone agent with an AI
coding agent" matched `coding agent` (12 chars) over `phone agent` (11), giving
coding advice for a voice build — silently, for the whole session. Now the
**earliest mention** wins; length is only a tiebreak. What someone names first is
what they are asking about.

`matchStackTool` in `stackRegistry.ts` still uses the older display-name-then-
keyword scan and has the same latent weakness. Left alone here because changing
tool selection is a separate, higher-blast-radius change.

## What it costs us

- **Prompt budget.** The brain and rules ride along on every turn beside a
  screenshot. Hard caps (6 projects, 12 skills, 12 tools, 10 mistakes) keep it
  bounded; unbounded memory does not fail loudly, it quietly makes answers worse.
- **The model is the writer.** If it never emits tags, the brain stays empty and
  Teachy is no worse than before — but no better. Whether it actually writes them
  in practice is **unverified**; that needs a signed-in run.
- **No UI to view or correct the brain.** A learner cannot see or fix what Teachy
  believes about them, which will be wrong sometimes.
- **Rules are Teachy's opinions.** Vapi for voice, Vercel for deploy. Wrong for
  someone already on Twilio or Netlify, and the coach is told to follow them over
  generic advice.

## When to revisit

Add a brain viewer/editor once anyone has used this for a week — being unable to
correct a wrong belief will bite before the caps do. If the model turns out not to
emit tags reliably, move extraction to a cheap second call rather than abandoning
the structure.
