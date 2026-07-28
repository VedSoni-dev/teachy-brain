# 0006 — Git plus graphify is the company memory

**Date:** 2026-07-28
**Status:** accepted
**Affects:** how anyone — human or agent — finds out what Teachy knows

## The question

Teachy wants to be an AI-native company: everything stored, everything
queryable. Candidates considered were gbrain, supermemory, Obsidian, and
"markdown in git plus a generated index".

## Decision

**Plain markdown in git is the source of truth. graphify is the query layer.**

The store is this repo. The index is a knowledge graph generated from this repo
and the two code repos, regenerated on demand and never hand-edited.

## Why not the others

**supermemory** — a hosted service. It puts company strategy on someone else's
infrastructure, behind an account and an API key, and creates a store that cannot
be diffed, reviewed, or restored from a git tag. The failure mode is silent: an
expired key or a dead vendor takes the company memory with it.

**Obsidian** — good for humans, and the vault is markdown, which is right. But
"dreaming" and the plugin ecosystem are a human reading experience, not an agent
query interface, and the value here is agents answering questions without a
person in the loop. Nothing stops anyone opening this repo *in* Obsidian — it is
markdown in folders, which is exactly a vault. That option stays free.

**gbrain** — genuinely close, and a real candidate. **This rejection was reversed on 2026-07-28; see [0009](0009-gbrain-indexes-the-brain.md).** It was rejected because it
introduces a second durable store solving a problem git already solves. Two
stores drift; the one that is easier to write to wins, and the other rots into a
lie. If a database-backed brain is wanted later, it should be **generated from**
this repo, not written to alongside it.

## Why this holds up

- **Durable without maintenance.** Markdown in git needs no server, no schema
  migration, and no vendor. It will open in ten years.
- **Reviewable.** A change to what the company believes arrives as a diff someone
  can argue with, not as a silent row update.
- **Already blessed.** graphify is installed and already a standing rule in the
  operator's global agent config, so agents reach for it without being told.
- **The index is disposable.** `graphify-out/` is generated. If the graph is
  wrong, delete and rebuild — there is no state to lose, because the truth is the
  markdown.

## The rule that keeps it honest

**Never edit the graph. Never treat it as the source.** If something is true, it
is written in markdown and committed. The graph is a view.

## What it costs us

Markdown in git has no recall beyond text search and whatever the graph extracts.
There is no semantic search, no "what did we say about pricing" that finds a
paragraph phrased three other ways. A hosted memory product would have given us
that on day one; we chose durability over retrieval quality, and that is a real
loss, not a technicality.

It also depends on graphify — a single tool, on PATH, that we do not control. If
it breaks or changes its output format, the query layer goes with it. The
markdown survives, which is exactly why it is the source, but "queryable" would
degrade to grep until someone fixed it.

And the honest one: **git does not make anyone write things down**. This decision
solves storage and retrieval. It does nothing about capture, and capture is the
part that actually fails. That gap is what the automation around it — hooks,
brain-status, the write-back protocol — exists to close, and it is closed by
convention rather than by the storage choice.

## Revisit when

graphify stops being maintained, or retrieval quality becomes the thing blocking
people — at which point the answer is an embedding index *generated from* this
repo, not a second place to write.

## See also

- [QUERYING.md](../QUERYING.md) — how to actually ask this thing questions
- `scripts/rebuild-graph.ps1` — regenerates the cross-repo graph
