# 0023 — Wipe the engine; rebuild from scratch

**Date:** 2026-07-30
**Status:** accepted
**Affects:** teachy-app (deleted), teachy-b2b (deleted), teachy-web (kept), this repo (kept)

## The decision

Ved called it: delete the local `teachy-app` (engine + B2C) and `teachy-b2b`
working copies and remake the product from scratch. Keep `teachy-web` and this
brain. The use cases survive; the code does not.

What still binds the rebuild — these are product decisions, not code:

- Teachy shows; never acts in the learner's work ([0014](0014-teachy-shows-never-acts.md))
- OpenClaw-shaped teaching runtime: soul, durable memory, think, plan, heartbeat,
  first-session bootstrap ([0013](0013-teachy-agent-runtime.md), 0022)
- Active prompter, doing beats navigating, artifact-ended paths (`product/course-design.md`)
- A learner brain the learner can correct ([0021](0021-one-brain-the-learner-can-correct.md))
- BYOK / borrowed subscription, no hosted proxy ([0001](0001-bring-your-own-key-not-a-hosted-proxy.md), [0015](0015-borrow-a-subscription-over-acp.md))
- A&M wedge: distribution × reliability × taste ([0012](0012-own-am-openclaw-ai-fluency.md))

Open for the rebuild: the stack itself. 0011 (Electron + React) and 0003
(C# sidecar) described the wiped implementation and are no longer binding.

## Safety net

- Tarballs (working tree + `.git`, no node_modules) in `teachy/wiped-2026-07-30/`.
- The GitHub remotes were **deleted too**, same day, on Ved's explicit
  confirmation. The tarballs are the only surviving copy of the engine —
  including final commit `b95c0a5` (the 0022 soul workspace, never pushed) and
  an uncommitted studio/dock refactor. Losing `wiped-2026-07-30/` loses the
  engine's entire history.
- Old `VedSoni-dev/teachy` (Swift era, private) and `teachy-releases` (Sparkle
  feed) remain on GitHub — never in scope.

## What it costs us

- Everything unreleased dies with the working copies: the studio window,
  the soul workspace wiring, the learner-brain UI. Real weeks of work.
- The cross-repo graph is stale until the new engine exists and is re-indexed.
- Decisions 0003, 0011, 0016–0018 now describe a dead codebase; they remain as
  history, not guidance.

## When to revisit

When the new engine has its first runnable slice, write the new stack decision
that replaces 0011 — and pull the soul/doctrine text out of the tarball rather
than rewriting it from memory; it was the most recently-tuned artifact we had.
