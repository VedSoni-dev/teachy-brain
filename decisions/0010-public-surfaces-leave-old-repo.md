# 0010 — Public surfaces leave the old combined repo; appcast stays

**Date:** 2026-07-28
**Status:** accepted
**Affects:** downloads, academy registry, Mac catalog defaults, Sparkle updates

## The question

After the three-repo split, what still has to resolve against
`VedSoni-dev/teachy`, and what can move?

## The decision

**Cut every learner-facing URL off the old repo except Sparkle `appcast.xml`
(and the historical release assets it points at).**

Concrete targets:

| Surface | Points at |
|---|---|
| Download / DMG | `VedSoni-dev/teachy-releases` |
| Course registry + `installURL` | `teachy-releases` (public raw) |
| Live Academy site | Vercel (`teachy-ashy.vercel.app`) |
| Mac catalog defaults | `teachy-releases` registry + Vercel |
| Auto-update | **still** `VedSoni-dev/teachy` `appcast.xml` |

## Why

Shipped Mac binaries have the appcast URL compiled in. That URL cannot move for
v1.0/v1.1 installs, ever. Everything else was still hitting the combined repo out
of inertia and would keep teaching the wrong "source of truth."

Course `installURL`s go to `teachy-releases`, not `teachy-app`, because
`teachy-app` is private — raw.githubusercontent.com returns 404, and a silent
failed install is worse than a deliberate public mirror.

## What it costs us

- Two public URLs to keep honest (`teachy-releases` registry vs `teachy-web`
  academy copy). They can drift; nothing fails loudly when they do.
- `vedsoni-dev.github.io/teachy` (gh-pages) becomes legacy. Old links still work
  until someone freezes or redirects it; Vercel is canonical.
- The old repo can never be deleted. Operators who treat "archive" as "delete"
  will brick every installed Mac copy's updater.

## When to revisit

When a future Mac build ships with an appcast URL on `teachy-releases` *and*
enough of the install base has updated that freezing the old appcast is an
explicit product call — not before.
