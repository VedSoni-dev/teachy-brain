# Dreaming

A periodic reflective pass over the brain. Borrowed from gstack's `gbrain dream`,
which runs mechanical phases and only then consolidates — the same split applies
here, for the same reason.

**A machine can find the candidates for rot. Only a reader can judge them.**
`scripts/dream.ps1` does the cheap, exhaustive half and writes a briefing;
Claude does the reflective half against it.

## Why this exists at all

Everything else in the brain is a *check*: is the graph current, does every
record carry its cost, does the index match the files. Checks catch structural
rot. They cannot catch **semantic** rot — a record whose reasoning quietly
stopped applying, two records that now contradict each other, a "revisit when"
condition that came true six weeks ago and nobody noticed.

Nobody re-reads decision records. That is not a discipline failure, it is just
what happens: they are written once, at the moment of maximum context, and then
they sit there being confidently out of date. Dreaming is the scheduled excuse to
re-read them.

## Running one

```bash
pwsh teachy-brain/scripts/dream.ps1
```

Writes `graph/dream-input.md` (gitignored — it is a working note, not a record).
It gathers:

1. **Every commit since the last dream**, across all three repos.
2. **Every "revisit when" condition**, pulled out of every record and listed
   together. This is the highest-value part: those conditions are invisible
   otherwise.
3. **The age of every document**, because a record written before a rewrite it
   never mentions is worth re-reading.
4. **The telemetry report** — what actually happened.
5. **Brain health** — the structural checks.
6. **Six questions** to answer, each with a concrete output.

Then read it and act. When done, stamp it:

```powershell
(Get-Date).ToString("o") | Set-Content graph/.last-dream
```

## When to dream

- After finishing a substantial piece of work.
- When `brain-status.ps1` has been reporting drift.
- When something surprising happened and you suspect a record now lies.
- Otherwise, whenever a while has passed and nobody has re-read anything.

Not on a fixed cadence. A dream with nothing to reflect on trains you to skim
them, and skimming is how the useful one gets missed.

## Whose job

Claude's, not Ved's — see the standing instruction in `CLAUDE.md`. He has said
explicitly he never wants to maintain this. Dreaming is part of finishing work,
not something to offer him as an option.

## It works — the first cycle proved it

The very first dream fired a real condition. Decision 0007 said:

> Telemetry exists, at which point decision records should carry an outcome and
> the health check should flag beliefs that reality has contradicted.

Telemetry had just landed in 0008, so the condition was already true and nobody
had noticed. That cycle produced: an `Outcome` section in the record template, an
`Outcome` on every record making a measurable claim, and a new `brain-status`
check that flags ungraded records **once there is evidence to grade them with**.

It also caught a bug in itself — the briefing was quoting our own records back
mojibaked, because Windows PowerShell reads as ANSI unless told otherwise.

That is the pattern to expect: a dream mostly produces small corrections, and
occasionally catches the thing that would have quietly rotted for months.
