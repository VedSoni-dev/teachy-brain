# 0017 — One engine, two editions: open-source B2C, closed B2B

**Date:** 2026-07-29
**Status:** accepted
**Affects:** teachy-app, teachy-b2b, release identity, all future feature work

## The question

Two near-identical desktop trees, and the only thing that legitimately differed
was two course files. That duplication had already caused one silent break
([0016](0016-b2b-desktop-had-never-been-built.md)) and made "add this feature to
both" a copy-paste job. But the obvious fix — one monorepo — is impossible here:
**B2C is open source and B2B must not be.**

## The decision

Split the engine out, and let the repo boundary fall on the licence boundary:

| Repo | Visibility | Owns |
|------|-----------|------|
| `teachy-app` | public, OSS | `packages/core` (the engine) **and** `apps/b2c` |
| `teachy-b2b` | private | `apps/b2b` only |

`teachy-b2b` resolves `@teachy/core` through an npm `file:` link to
`../teachy-app/packages/core`. Core edits are live in both products with no
publish step, and nothing proprietary ever enters the public repo — core is open
source regardless of which product loads it.

**The whole seam is one Vite alias.** Core imports `@teachy/edition`; each app
points that at its own module. An edition is a config entry plus a content module,
not a fork. `packages/core/vite/defineTeachyConfig.mjs` builds both.

`TeachyEdition` (`src/edition/contract.ts`) has no optional fields on purpose:
adding one forces every edition to answer for it, so a feature cannot silently
exist in one product and be `undefined` in the other.

## Every edition runs the whole shared suite

`verify` in either app runs **core's entire test suite plus that edition's own** —
28 files, ~264 tests each. A shared change is proven against both products before
it ships, which is precisely what the two-copy setup could not do.

The content rules that used to be a test file next to B2C's course data are now
`validateEdition()`, run by both editions against their own courses. B2B's content
had been validated by nothing at all.

## Policy is enforced in main, not the UI

`allowPersonalAcpRuntimes: false` is what stops a corporate build running on an
employee's personal Claude Pro subscription — the gap flagged in
[0015](0015-borrow-a-subscription-over-acp.md).

It is checked in `main/acp/policy.cjs`, not by hiding a button, because the chosen
runtime id lives in localStorage and outlives any UI that hid the option. B2B keeps
`allowCustomAcpHarnesses: true`: the company points Teachy at its own ACP agent, so
there is still a backend and learner data stays inside the perimeter that tool
already enforces.

## Swift is gone

Deleted from both repos, per Ved. 35k lines. Recoverable from `teachy-app@ec908f4`
and `teachy-b2b@ced850f` — teachy-b2b had **zero commits** before this work, so it
was committed first specifically to make the deletion reversible.

Consequence to be honest about: the Sparkle-updated Mac B2C app was the Swift one.
Mac users move to the Electron shell, which per
[0011](0011-mac-ships-electron-react.md) is the accepted direction but has a worse
Mac feel (click-through, Spaces, hold-to-talk) until the Mac host gains depth.

## `open-app`, once rather than twice

Mac and Windows already exposed an identical 22-command surface, so see/point/type
was at parity. Opening an *application* existed on neither.

Implemented in Electron main, not in macHost **and** the C# sidecar, because
launching an app works the same on both — and a second copy is exactly how the
desktop trees drifted. It resolves ids from a curated registry and refuses paths
and commands outright. `open-url` on both platforms carries the comment "this must
never become a way to launch programs"; that boundary is right, and a coaching tool
that starts arbitrary executables on request is a remote-execution primitive
wearing a teaching hat.

## What it costs us

- **teachy-b2b cannot build alone.** It needs `teachy-app` checked out as a
  sibling. A clone-and-build of B2B by itself fails on the `file:` link.
- **Core's public git history now carries B2C's product decisions**, since they
  share a repo. Fine while B2C *is* the open-source product; awkward if that ever
  changes.
- **A core change can break B2B without touching its repo.** That is the point,
  and it is why both editions run the full shared suite — but B2B's CI has to run
  on core changes too, which does not exist yet.
- **The Mac feel regression** above, inherited from 0011.

## When to revisit

If a third edition appears, nothing structural changes — add `apps/<name>`. If
core ever needs to ship to someone without the source, publish it as a real
versioned package instead of a `file:` link and accept the bump-and-publish loop.
