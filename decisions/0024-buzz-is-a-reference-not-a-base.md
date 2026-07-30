# 0024 — Buzz is a reference, not a base

**Date:** 2026-07-30
**Status:** accepted
**Affects:** the engine rebuild (0023), repo layout

## The question

The rebuild (0023) needed a seed. Ved cloned `block/buzz` (Apache-2.0) — a
self-hostable workspace where humans and agents share rooms on a Nostr relay:
Rust monorepo (26 crates), React web client, Tauri desktop, mobile.

Fork it into Teachy, or not?

## The decision

**Not a fork.** Ved's call, same session: Buzz is excellent and very OpenClaw,
but it is built for teams — agent teammates, shared rooms, multi-user relays.
Teachy is one person learning on one screen. Bending a collaboration platform
into a 1:1 tutor means fighting its core abstraction (the multi-member room)
forever.

The clone lives at `reference/buzz` as a study copy (remote: `upstream`).
What Teachy takes from it, by borrowing patterns or depending on crates:

- **`buzz-persona`** — persona packs as `.persona.md` files. This is the soul
  workspace from 0022 as a file format with a parser, instead of TS constants.
- **`buzz-agent` / `buzz-acp`** — a minimal ACP-compliant agent loop (stdio,
  JSON-RPC, tool-calls-as-output) and harness. Slots straight into 0015's
  borrow-a-subscription-over-ACP.
- **The event-log idea, single-user.** Every coaching turn, memory write, and
  milestone as one append-only signed log = learner history, the Brain tab,
  and replay for free — without the relay or rooms.

## What it costs us

- No upstream to ride: patterns copied from Buzz drift as Buzz evolves, same
  as the doctrine copy in 0021. Depending on crates directly mitigates this
  only where the crate is genuinely standalone.
- The 515M reference clone sits in the workspace, unindexed by the graph.
- Still no stack decision for the new engine (0023's open item stays open —
  though Buzz's Tauri + Rust core + React shell is now the leading candidate,
  since it makes crate reuse natural).

## When to revisit

If the new engine ends up depending on three or more Buzz crates, reconsider a
proper fork — at that point we are maintaining a divergent Buzz anyway. If
Teachy ever adds a second seat (parent, teacher, cohort), reread this record:
the room abstraction we rejected is exactly what that feature needs.
