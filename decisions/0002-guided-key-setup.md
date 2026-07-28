# 0002 — Guided key setup, and validate before saving

**Date:** 2026-07-28
**Status:** accepted
**Affects:** teachy-app Windows first run
**Implements:** the half of [0001](0001-bring-your-own-key-not-a-hosted-proxy.md) that makes BYOK survivable

## The question

Given BYOK, how does a non-technical learner actually get a key into Teachy?

## Decision

A five-screen flow that takes over the notch panel:

```
why  ->  make an account  ->  create the key  ->  paste it  ->  you're in
```

Teachy opens the correct OpenRouter page at each step (sign-up, then the keys
page) and names the exact buttons to click. The learner still creates their own
account and their own key — **Teachy never touches their credentials**, and that
is a hard line, not an implementation detail.

Two supporting rules:

1. **The key is validated against OpenRouter before it is saved.** It calls
   `/api/v1/key` and only stores what authenticates.
2. **A rejected key and an unreachable OpenRouter are different outcomes.** 401
   means "your key is wrong"; 5xx means "try again in a minute".

## Why those two rules matter more than the screens

The old settings field accepted any string, encrypted it, and said "Key saved".
A truncated paste got a green tick and then a wall of failures at the learner's
first question, with nothing anywhere pointing at the key as the cause. Nobody
debugs their way out of that; they close the app and don't come back. A setup
flow that ends in a lie is worse than no flow.

The 401-vs-5xx split matters because telling someone their brand-new key is
invalid during an OpenRouter outage sends them back through the entire signup
loop for nothing — and they will blame Teachy, correctly, for the wasted trip.

## Details that came out of contact with reality

- **Paste tolerance.** People paste with quotes, a trailing newline, or the whole
  `OPENROUTER_API_KEY=sk-or-…` line. Each of those used to read as an invalid
  key. The extractor pulls the key out of surrounding text.
- **Clipboard offer.** Ctrl+V into a frameless, non-activating window is awkward
  enough on its own to lose people, so the paste step offers what is on the
  clipboard. Pull-only, on an explicit step, shape-gated to `sk-or-`, and the UI
  says that it looked. It is never a background watcher.
- **The panel pins open during setup.** The flow deliberately sends the learner
  to their browser. Before this, the notch collapsed on pointer-leave and
  unmounted the flow, so they came back holding a key with the panel gone and
  their progress reset.

## See also

- `teachy-app/desktop/src/onboarding/KeySetup.tsx`
- `teachy-app/desktop/src/state/openRouterKey.ts`
