# 0001 — Bring your own key, not a hosted proxy

**Date:** 2026-07-28
**Status:** accepted
**Affects:** teachy-app (Windows + macOS), unit economics, first-run funnel

## The question

Teachy needs an AI model to think. Two ways to pay for it:

- **BYOK** — the learner creates their own OpenRouter account and key. Their usage
  bills to them.
- **Hosted proxy** — Teachy runs a worker, holds one key, and eats inference cost
  for every learner.

The macOS app already routes through a `WorkerBaseURL` abstraction and a
`worker/` directory exists, so the proxy path was already half-built.

## Decision

**BYOK.** The proxy stays available for the Mac's existing path but Windows does
not adopt it, and BYOK is the shipped default everywhere.

## Why

A hosted proxy turns every new user into a variable cost with no revenue
attached. At the scale Teachy is aiming for — "millions of people learning to
build" — a viral spike becomes a bill, and the only levers left are rate limits
or shutting it off. Both make the product worse exactly when it is working.

BYOK also keeps a promise that is easy to make and hard to walk back: the
learner's usage is on their own account, against a key they can revoke, and
Teachy never sees a bill for their curiosity.

## What it costs us

BYOK's honest price is the first run. "Paste your OpenRouter API key" asks
someone who came here to build a website to already know what an API key is,
where OpenRouter lives, and which of its pages issues one. That is a funnel
cliff, and pretending otherwise is how BYOK products die.

So the decision is only viable **with** the guided setup flow — see
[0002](0002-guided-key-setup.md). BYOK without that flow is not a cheaper
product, it is a product nobody finishes installing.

## Revisit when

- A measurable share of first runs abandon at key setup even with the guided
  flow. Instrument it before arguing about it.
- Teachy has revenue that can absorb inference for a free tier — at which point
  the answer is probably *both*: a proxy-backed trial that converts to BYOK.

## See also

- [0002 — Guided key setup](0002-guided-key-setup.md)
- `teachy-app/worker/` — the proxy that exists but is not the default path
