# Working in teachy-brain

This is Teachy's company memory. Markdown in git is the source of truth; the
knowledge graph is a generated view over it.

## Answer from the graph before reading files

A cross-repo graph covering teachy-app, teachy-web and teachy-brain lives at
`../graph/teachy-graph.json`. For structural questions — what calls this, how do
these connect, what breaks if I remove it — query it instead of grepping:

```bash
graphify explain "<thing>" --graph ../graph/teachy-graph.json
graphify path "<a>" "<b>" --graph ../graph/teachy-graph.json
```

For *why* questions the graph is the wrong tool. Read `decisions/`.

See [QUERYING.md](QUERYING.md) for the full map.

## When you make a decision, write it down

Add a numbered record in `decisions/`. Same shape every time:

- the question
- the decision
- why
- **what it costs us** — not optional; a record with no downside listed reads as
  marketing and gets ignored later
- when to revisit

## After changing anything

```bash
pwsh scripts/rebuild-graph.ps1
```

Never hand-edit `graphify-out/` or `../graph/`. Both are generated and gitignored.

## What does not belong here

Engineering documentation about how code works lives with that code, in
teachy-app. The split is: *why we are building this* here, *how this code works*
there. See [decision 0005](decisions/0005-three-repos.md).

## Write back what you learn - this is not optional

Before finishing a session in which you made an architectural choice, found
something surprising, or implemented a call the user made in conversation:

```bash
pwsh scripts/new-decision.ps1 "<the call, as a short sentence>"
```

A decision made in chat and implemented in code leaves no record of the reasoning
anywhere - the code shows what, the commit shows what changed, and the why dies
when the session ends. That is the single way this system fails.

Full protocol, including when NOT to record: `WRITE-BACK.md`.
Check yourself with `pwsh scripts/brain-status.ps1`.

## Dreaming - run one after substantial work

`pwsh scripts/dream.ps1` gathers a briefing (commits since the last dream, every
"revisit when" condition, document ages, telemetry, health) into
`../graph/dream-input.md`. Read it, answer its six questions, act, then stamp:

```powershell
(Get-Date).ToString("o") | Set-Content ../graph/.last-dream
```

Checks catch structural rot. Dreaming catches semantic rot - a record whose
reasoning quietly stopped applying, or a revisit condition that came true weeks
ago and nobody noticed. Full protocol: DREAMING.md.

This is Claude's job, not Ved's. He has said explicitly he never wants to
maintain the brain. Do it as part of finishing work; do not offer it as an option.

## Standing context

Repeated here rather than left to memory files: those are keyed to the workspace
root (C:\Users\vedan\teachy), so a session started inside this repo loads none of
them. This block always loads.

- **Ved never maintains the brain.** Keeping decisions, incidents and known
  issues current is Claude's job, done as part of finishing work - not offered as
  an option.
- **He wants the call made, not a menu.** Decide, act, state the honest cost in a
  sentence. Reserve questions for money, publication, and product direction.
- **Never declare victory.** Name what is still missing. Verify by running things.
- **The workspace** is three repos side by side: `teachy-app`, `teachy-web`,
  `teachy-brain`, plus a generated `graph/`.
