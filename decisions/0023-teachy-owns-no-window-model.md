# 0023 — Teachy owns no window model: one session, no tabs, a four-tab Studio budget

**Date:** 2026-07-30
**Status:** accepted
**Affects:** `studio/Studio.tsx`, `tabs/`, `dock/`, `useCourseSession.ts`, B2B edition layer

## The question

Teachy's advantage over OpenClaw is the visual hand-holding — the capsule and the
Spark beacon that point at real UI. The temptation that follows is to grow the
rest of an OpenClaw-style client around it: session tabs, background windows,
several conversations at once. Does Teachy get a window model, and if so what do
opening, closing and backgrounding a tab mean?

The alternative on the table was real: **build the simplest, most idiot-proof
OpenClaw of all time** — the same surface, fewer knobs.

## The decision

**Teachy owns attention, not windows.** Concretely:

1. **No session tabs, ever.** One active course session, enforced in code, not by
   convention. Starting a second course swaps, behind a confirmation that names
   the progress at risk ("you're 3 goals into Build a Website").
2. **The learner's own windows are the tabs.** They already have Chrome tabs, an
   editor and a terminal. The capsule gains a **focus target** — the app the
   current goal is anchored to. Alt-tab away and the capsule dims and waits; it
   does not follow and does not nag. That rides the one-nudge heartbeat guard
   from [0022](0022-soul-as-an-openclaw-workspace.md) rather than adding a second
   attention mechanism.
3. **Studio is four tabs — Learn / Progress / Brain / Settings — permanently.**
   A new surface fits inside one of them or displaces one. There is no fifth.
4. **If concurrency is ever genuinely needed** (a B2B rep across several tracks),
   paused sessions are **cards in Progress with Resume** — a queue, not tabs.
   Tabs imply simultaneity; cards imply order.

## Why

- [0014](0014-teachy-shows-never-acts.md) and 0022 already commit Teachy to
  pointing at the learner's real screen and never acting inside their work. A tab
  bar inside Teachy stands up a **second window model competing with the one the
  learner already has**, and the beacon then has to point across the seam.
- OpenClaw-minus-features is a worse OpenClaw. Anyone who wants OpenClaw will run
  OpenClaw. Teachy's learner would never install it. The axis is not *simpler*,
  it is **nothing to configure at all**.
- The rollout test from [0012](0012-own-am-openclaw-ai-fluency.md): 500 Aggie
  Innovators, one build, one sitting. Any concept that has to be explained fails
  it. "Hold ctrl+option and follow the beacon" survives. A tab model does not.
- The real fear behind the question was rebuilding OpenClaw feature by feature.
  That is solved by a **budget rule**, not by willpower. Rule 3 is the budget.

## What it costs us

- A learner running two tracks in a week has to switch rather than glance. Real
  cost, accepted — nobody learns two things at once anyway.
- The four-tab budget will eventually block something genuinely good, and the
  displacement argument will be tedious to have. That is the point of it.
- The focus target is **new work, not free**: it needs a foreground-window read on
  both OSes. Mac has `get-screen-info` / `inspect-elements` in `macHost.cjs`;
  Windows has UI Automation in the sidecar. Two implementations of one indicator.
- It rules out, for now, an obvious B2B ask: a manager watching several learners'
  sessions side by side. That is a different product surface, not a tab.

## When to revisit

- If B2B pilots report the queue genuinely blocks work — a rep who must hold two
  tracks open against live customer sessions — promote the Progress shelf to a
  first-class surface **before** anyone reconsiders tabs.
- If the focus target proves unreadable on Windows multi-monitor (the overlay is
  primary-display only today, per `known-issues.md`), ship the dim without the
  app icon rather than shipping nothing.
- If a learner ever has to be told how Teachy's windows work, rule 1 has been
  broken somewhere.
