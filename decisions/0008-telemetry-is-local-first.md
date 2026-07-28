# 0008 - Telemetry is local-first, and grades the decisions

**Date:** 2026-07-28
**Status:** accepted
**Affects:** teachy-app (Windows), every decision record that made a claim about learners

## The question

[0007](0007-the-brain-maintains-itself.md) made the brain notice its own rot, and
listed the gap it did not close: "the brain records intent, never outcome - it
can be perfectly maintained and perfectly wrong."

Concretely, three records assert things nothing has ever checked:

- [0001](0001-bring-your-own-key-not-a-hosted-proxy.md) accepts a funnel cliff as
  the price of BYOK.
- [0002](0002-guided-key-setup.md) claims the guided flow fixes that cliff, and
  says outright: "instrument it before arguing about it."
- [0004](0004-one-flagship-course.md) bets the product on people finishing one
  course.

So: how do we find out whether any of that is true, without a server, without a
consent regime, and without a cost that grows with users?

## Decision

**A local, append-only event log, and a report that reads it against the specific
questions the decision records left open.**

The app appends JSONL to `$TEACHY_HOME/events.jsonl`. Nothing is transmitted.
`teachy-brain/scripts/telemetry-report.ps1` reads that log and prints the key
setup funnel, the course funnel, and failures by category - each labelled with
the decision it grades.

**Privacy is enforced in the sink, not requested of callers.** The main process
filters every payload through an allow-list of primitive fields with a length
cap. Screen content, prompts, model replies, learner speech and API keys cannot
land in the log even if a caller passes them - because the sink drops anything
not explicitly allowed, rather than trusting call sites to be careful. This app
watches a screen and hears people talk; an event log that accepts arbitrary
payloads is one careless line away from being a transcript.

**Telemetry can never break the app.** Recording is fire-and-forget, never
awaited, and returns false rather than throwing. A learner mid-course must never
hit a failure caused by measurement.

## Why local-first

Remote aggregation needs a server (a cost that scales with users, which is the
exact thing [0001](0001-bring-your-own-key-not-a-hosted-proxy.md) refused), a
privacy policy, a consent flow, and a data-retention answer. That is a real
project with a real ongoing obligation.

Local costs nothing, ships today, and answers the questions we actually have
right now - because the people running Teachy today are the founder and early
dogfooders, and their logs are the only data that exists. Building the fleet
version first would be instrumenting for users we do not have.

## What it costs us

**One machine is not a fleet.** Every number this produces is from one install.
It cannot tell you conversion, retention, or anything about people who are not
you. The report says so in its own output, because a funnel percentage looks
authoritative regardless of its sample size, and this one will be quoted.

**Someone has to run the report.** Nothing surfaces these numbers automatically -
they do not appear in `brain-status.ps1` and no hook prints them. The brain will
still happily hold an ungraded claim indefinitely.

**Quitting is derived, not measured.** Found by testing rather than reasoning:
killing the app mid-setup fires no abandonment event, because the React unmount
handler never runs. Since closing the app is the most common way to abandon
anything, depending on that event would have reported near-zero abandonment and
read as a triumph. The report derives quits as shown minus completed minus
dismissed. That is honest but coarse - it cannot tell you *which* step a quitter
was on, only the furthest step of the most recent attempt.

**More code in the coaching path.** Every instrumented call site is a line that
can throw, and the mitigations (allow-list, try/catch, fire-and-forget) are
themselves code that can be wrong. Eleven tests cover the sink specifically
because the failure modes here are silent.

**It measures what is easy, not necessarily what matters.** Steps and outcomes
are countable. Whether the coaching was any good is not, and nothing here gets
closer to that.

## Revisit when

- There are enough users that per-machine logs stop being the only data - at
  which point opt-in aggregation is its own decision, with a privacy story.
- A decision record has been sitting ungraded for a month while the report has
  the answer, which means the reporting needs to be pushed rather than pulled.

## See also

- `teachy-app/desktop/electron/telemetry.cjs` - the sink and its allow-list
- `teachy-app/desktop/tests/telemetry.test.ts` - privacy invariants
- `scripts/telemetry-report.ps1` - the report
