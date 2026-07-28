# Teachy Brain

Company memory. What Teachy is for, who it's for, why it's built this way, and
what we learned when it broke.

Markdown in git is the source of truth. A generated knowledge graph makes it
queryable. There is no database, no account, and no service to keep alive — see
[decision 0006](decisions/0006-git-and-graphify-as-the-company-memory.md).

**Start here:** [QUERYING.md](QUERYING.md) — how to actually ask this thing
questions.

## Layout

| Folder | What |
|--------|------|
| `decisions/` | numbered decision records — the question, the call, why, **what it cost us**, when to revisit |
| `engineering/` | architecture, known issues, and incident write-ups |
| `company/` | what the product is, who it's for, the enterprise story |
| `product/` | how a Teachy course is designed, with examples and reference |
| `launch/` | launch copy, video brief, demo shot list, changelog |
| `scripts/` | `rebuild-graph.ps1` |

## The decisions, so far

| # | Decision |
|---|----------|
| [0001](decisions/0001-bring-your-own-key-not-a-hosted-proxy.md) | Bring your own key, not a hosted proxy |
| [0002](decisions/0002-guided-key-setup.md) | Guided key setup, and validate before saving |
| [0003](decisions/0003-windows-is-electron-plus-a-csharp-sidecar.md) | Windows is Electron plus a C# sidecar |
| [0004](decisions/0004-one-flagship-course.md) | One flagship course, not a catalog |
| [0005](decisions/0005-three-repos.md) | Three repos: app, web, brain |
| [0006](decisions/0006-git-and-graphify-as-the-company-memory.md) | Git plus graphify is the company memory |

## Querying

```bash
graphify explain "MicrophoneRecorder" --graph ../graph/teachy-graph.json
graphify path "KeySetup" "openRouterKey" --graph ../graph/teachy-graph.json
pwsh scripts/rebuild-graph.ps1
```

The graph is a view. If it disagrees with the markdown, the markdown wins and the
graph needs rebuilding.

## What lives elsewhere, deliberately

Engineering design docs (`docs/design/`) and `AGENTS.md` stayed in **teachy-app**.
A document explaining why the Windows sidecar is a separate process is only
useful next to that process. The split is: *why we are building this* here, *how
this code works* with the code.

## Repository layout

| Repo | Holds |
|------|-------|
| **teachy-app** | macOS + Windows apps, `courses/`, `connectors/`, the `worker/` proxy |
| **teachy-web** | the Academy site and its deploy config |
| **teachy-brain** (this one) | strategy, decisions, incidents, launch, course design |
