# 0018 — B2B stays proprietary; publish Electron world; wipe Swift residue

**Date:** 2026-07-29
**Status:** accepted
**Affects:** teachy-b2b license, GitHub remotes, intern onboarding, CI

## The question

After the one-engine split ([0017](0017-one-engine-two-editions.md)), the trees
were correct locally but (1) teachy-b2b still carried an MIT LICENSE file that
contradicted the closed-source call, (2) nothing was on GitHub, and (3) disk +
docs still advertised Swift/Xcode.

## The decision

1. **teachy-b2b is proprietary / All Rights Reserved** — replace MIT. The engine
   in teachy-app remains MIT; only the edition layer is closed.
2. **Publish** teachy-app’s Electron main (`monorepo-core-split` → `main`), create
   a **private** GitHub repo for teachy-b2b, push teachy-brain’s edition records.
3. **Wipe** Swift husks from disk (empty xcodeproj, `.claude` worktrees with old
   `.swift`, `swift-build.yml`). Docs (`README`, `AGENTS`, `INTERN.md`) and CI
   describe Electron only. `npm run verify` is what CI runs.

## Why

An unpaid intern (or future agent) cloning GitHub would otherwise get the old
Swift world, or a “MIT” B2B that is not MIT. Local leftovers are worse than
missing docs — they revive the wrong stack by tab-complete.

## What it costs us

- Closed B2B means no outside contributors on workplace curriculum; all engine
  improvements must land in public teachy-app first.
- Private B2B CI must check out public teachy-app as a sibling — more moving
  parts than a single monorepo.
- Sparkle-era README badges / release URLs may still point at pre-Electron
  artifacts until a separate release pass updates them.

## When to revisit

If Teachy for Work should become open source after all, or if a third edition
needs its own private remote.
