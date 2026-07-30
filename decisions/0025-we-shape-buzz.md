# 0025 — We shape Buzz

**Date:** 2026-07-30
**Status:** accepted
**Supersedes:** [0024](0024-buzz-is-a-reference-not-a-base.md), same day

## The decision

Ved reversed 0024 within the hour, and the reversal is the record that matters:
**Teachy is built by shaping Buzz itself, not by extracting parts from it.**
His words: don't try to limit Buzz. The clone is the engine again — it lives at
`teachy-app` (remote `upstream` → `block/buzz`, Apache-2.0).

What stands from 0024's analysis: the tension is real. Buzz is built for teams
and multi-member rooms; Teachy is one person learning on one screen, and
0014's shows-never-acts rule still has no answer in a platform whose agents
ship patches. Those are now *shaping problems inside Buzz* — a single-user
posture, a teaching persona, a constrained agent surface — not reasons to
avoid the platform.

## Why

Buzz already runs the hard parts Teachy spent months hand-rolling: agent
identity, persona packs, ACP, durable event-log memory, workflows. Rebuilding
those alone to keep the product "small" repeats the wiped engine's mistake in
a new stack. Better to start from a working whole and carve.

## What it costs us

- We inherit a 26-crate Rust monorepo + React/Tauri surface we didn't write.
  Understanding it is the new onboarding cost.
- Diverging from upstream while tracking it is a real maintenance tax; every
  reshaped surface is a future merge conflict.
- The single-learner product now depends on infra sized for communities
  (Postgres, Redis, Typesense, MinIO behind Docker) even on one laptop.

## When to revisit

After the first Teachy-shaped slice ships inside Buzz (a teaching persona
coaching one learner), write the decision on what "single-user Buzz" means
concretely — what got hidden, what got removed, what stayed. If the merge tax
from upstream drift exceeds a day per month, revisit tracking `block/buzz` at
all.
