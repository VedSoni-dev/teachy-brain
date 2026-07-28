# 0009 - gbrain indexes the brain (reversing part of 0006)

**Date:** 2026-07-28
**Status:** accepted
**Supersedes:** the gbrain rejection in [0006](0006-git-and-graphify-as-the-company-memory.md)
**Affects:** how anyone asks the brain a question

## The question

[0006](0006-git-and-graphify-as-the-company-memory.md) rejected gbrain, on the
grounds that it "adds a second durable store solving a problem git already
solves; two stores drift, and the one that is easier to write to wins while the
other rots into a lie."

Ved asked for it twice anyway. That is a reversal, and reversals belong in a
record rather than in a quiet change of behaviour.

## Decision

**gbrain is installed and indexes the brain. It is a view, not a store.**

Local PGLite at `~/.gbrain/brain.pglite`. Registered as a user-scope MCP so
`mcp__gbrain__*` tools are callable. `rebuild-graph.ps1` re-imports all three
repos on every commit, alongside the graphify rebuild.

The division that fell out of actually installing it:

| Tool | Answers |
|---|---|
| **gbrain** | *why* — semantic questions over decisions, incidents, architecture |
| **graphify** | *where* — structural questions over code |
| **markdown in git** | the truth both of them index |

## Why the original objection does not apply

0006's argument was about a second place to **write**. That was the right worry
and it is not what happened: nothing writes to gbrain by hand. It imports from
the same git-backed markdown that graphify reads, on the same trigger, and can
be deleted and rebuilt from zero at any time.

So there is still exactly one source of truth. There are now two indexes over
it, which is a different and much cheaper thing.

The capability is real and not something the graph could do. Asked *"why did we
choose bring your own key instead of a hosted proxy"* — a question with almost no
lexical overlap with the filename — gbrain ranked 0001 first, then 0002. The
knowledge graph indexes structure and could not have answered that.

## What it costs us

**A second thing that can rot, with a second failure mode.** Mitigated by
rebuilding on the same commit hook, but that mitigation is itself code, and
`rebuild-graph.ps1` has already broken twice this week.

**Semantic search is degraded until an embedding key exists.** gbrain wanted
`OPENAI_API_KEY` / `VOYAGE_API_KEY` / `ZEROENTROPY_API_KEY`; it was initialised
with `--no-embedding`, so retrieval is keyword/FTS rather than true semantic
similarity. It already beats grep, but the headline capability is half-on, and
`gbrain doctor` reports this as a warning rather than hiding it.

**No code indexing.** The `gbrain-base-v2` schema pack is markdown-only, so
`code-def` / `code-refs` / `code-callers` return nothing and `reindex-code` says
"no code pages". Code questions still go to graphify. Two tools to remember
instead of one.

**Another install on every new machine.** `bootstrap.ps1` does not yet install
gbrain, so a fresh workspace gets the graph and not the semantic index, with
nothing saying so.

**It is a git clone of someone else's project on PATH.** `~/gbrain`, linked via
`bun link`, tracking its default branch. That is a supply-chain surface the
markdown-in-git approach did not have.

## Revisit when

- An embedding key exists — at which point run `gbrain embed --stale` and this
  record's "half-on" caveat should be struck.
- gbrain's index and the markdown disagree, which would mean the import is not
  actually running on the hook.
- `bootstrap.ps1` gains gbrain install, closing the new-machine gap.

## Outcome

Not yet measured. Working on this machine; unproven on a second one.

## See also

- [0006](0006-git-and-graphify-as-the-company-memory.md) - the reasoning this partially reverses
- [QUERYING.md](../QUERYING.md) - which tool answers which question
