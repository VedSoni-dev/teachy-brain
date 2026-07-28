# The write-back protocol

**For agents.** This is the part of the brain that does not maintain itself
automatically, so it is written as an instruction rather than a hope.

Everything else is automated: the graph rebuilds on commit, staleness is a check
with an exit code, drift gets reported before a push. Capture is the one step
that still needs a decision from whoever is doing the work — because only they
know whether what just happened was a decision or a keystroke.

## When to write a decision record

Write one when **any** of these is true:

- You chose between real alternatives and the losing option was defensible.
- You changed how something is structured — a boundary moved, a dependency was
  added or cut, a process was split or merged.
- You found out something surprising about how the system behaves, and the next
  person would waste hours rediscovering it.
- You deliberately did *not* do something that looks obviously worth doing.
- The user made a call in conversation that will outlive the conversation.

That last one matters most. A decision made in chat and implemented in code
leaves **no record of the reasoning anywhere** — the code shows what, the commit
shows what changed, and the why dies with the session. That is the exact failure
this repo exists to prevent.

## When NOT to

- Bug fixes with an obvious right answer. The commit message is enough.
- Renames, formatting, dependency bumps.
- Anything you would not stop a colleague to explain.

Over-recording is its own failure. Twenty records nobody reads teach people that
records are not worth reading, and then the five that matter get skipped too.

## How

```bash
pwsh teachy-brain/scripts/new-decision.ps1 "Fetch the model list at runtime"
```

Fill in every section. **"What it costs us" is mandatory** and is checked — a
record without it fails `brain-status.ps1`. If you genuinely cannot name a cost,
that is a strong signal it was not a decision, and you should delete the file
rather than invent a downside.

Then add it to the table in `README.md` — also checked — and commit. The graph
rebuilds itself.

## Incidents

If something broke in a way that changed your understanding, write it up in
`engineering/incidents/` as `YYYY-MM-DD-short-name.md`: what happened, root
cause, why it was damaging, the fix, and **what it changed beyond the fix**.

That last section is the whole value. The sidecar crash write-up is worth reading
not because of the race condition but because it changed three unrelated things:
how the sidecar is supervised, that raw errors are never spoken aloud, and that a
non-atomic write was a real risk rather than a theoretical one.

## Known issues

If you find something broken and do not fix it, add it to
`engineering/known-issues.md` with a severity and a plain statement of what it
costs a learner. An unrecorded known issue gets rediscovered from scratch by the
next person, who then also has to work out whether it is already known.

## Checking your work

```bash
pwsh teachy-brain/scripts/brain-status.ps1
```

Green means the graph is current, every decision has its cost section, the README
index matches the files, and the brain has heard about recent work. The pre-push
hook runs this and warns — it deliberately does not block, because a hook that
blocks a push over documentation gets bypassed within a week and then catches
nothing while still looking like a safety net.
