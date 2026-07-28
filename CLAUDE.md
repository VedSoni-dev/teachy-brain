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
