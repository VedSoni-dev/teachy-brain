# 0014 — Teachy shows; never does it for them

**Date:** 2026-07-29
**Status:** accepted
**Affects:** Ask loop, course HUD, SOUL, agent hands

## The decision

Teachy's mission is **AI fluency by doing**. The product shows the next move
(point, speak, hint, verify). It does **not** click, type, or finish steps for
the learner — including when they ask "do it for me."

Removed: Ask → `runAgentLoop` takeover, course **"Do it for me"** button, and
stuck-path offers to take over. `agentLoop.ts` may remain as unused scaffolding
until deleted; it must not be wired to learner UX.

## Why

Fluency requires their hands on the work. Acting for them trains dependence.
OpenClaw-style memory/plan/think stays — autonomy is for *teaching grip*, not
remote control.
