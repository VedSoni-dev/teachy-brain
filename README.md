# Teachy Brain

Company memory. What Teachy is for, who it's for, why it's built this way, and
what we learned when it broke.

Markdown in git is the source of truth. A generated knowledge graph makes it
queryable. There is no database, no account, and no service to keep alive — see
[decision 0006](decisions/0006-git-and-graphify-as-the-company-memory.md).

## New machine / unpaid intern — paste into Claude Code

Works on **Windows or Mac**. Open Claude Code in the folder where the workspace
should live, paste the block below, let it run. Fuller notes: [SETUP.md](SETUP.md).

```
Set up my Teachy workspace on this machine (Mac or Windows — detect which).

Goal: a sibling checkout layout that can build and run the Electron Teachy apps.

1. Prerequisites — install anything missing, then continue:
   - git, gh (authenticated: `gh auth login` if needed), Node 18+
   - On Windows also: .NET SDK 8 (C# sidecar)
   - Optional: PowerShell 7 (`pwsh`) for brain scripts; `pip install graphifyy` for the knowledge graph

2. Clone / refresh via the brain bootstrap (preferred):
   - If teachy-brain is not here yet: `gh repo clone VedSoni-dev/teachy-brain`
   - Windows: `pwsh -ExecutionPolicy Bypass -File teachy-brain/scripts/bootstrap.ps1`
   - macOS/Linux: `bash teachy-brain/scripts/bootstrap.sh`
   That creates `teachy/` with teachy-app, teachy-web, teachy-brain; clones private
   teachy-b2b only if this GitHub account can see it; runs `npm install`,
   `npm approve-scripts electron` when available, and `npm run verify`.

3. If bootstrap is unavailable, do it by hand next to each other:
   teachy/
     teachy-app/    # public — engine + B2C
     teachy-web/
     teachy-brain/
     teachy-b2b/    # private — skip if no access
   Then:
   - `cd teachy-app && npm install && npm approve-scripts electron && npm run verify`
   - If teachy-b2b exists: same three commands there (it file:-links `../teachy-app/packages/core`)

4. Prove it boots (don't claim victory on verify alone):
   - `cd teachy-app && npm run start` — tray / notch UI
   - If launch says Electron failed to install: re-run `npm approve-scripts electron`
     or `node node_modules/electron/install.js`, then start again
   - Mac smoke alternate: see teachy-app/DEVELOPMENT.md (exit 2 = Screen Recording)

5. Read and report back:
   - teachy-app/INTERN.md
   - teachy-app/DEVELOPMENT.md
   - teachy-brain/decisions/0014-teachy-shows-never-acts.md
   - teachy-brain/decisions/0017-one-engine-two-editions.md
   - teachy-brain/engineering/known-issues.md — what is still broken

Hard rules:
- There is NO Swift app, NO Xcode project, NO `leanring-buddy`, NO `desktop/` app folder.
- Teachy shows the next move; do not restore "Do it for me" / autonomous learner hands.
- teachy-b2b is proprietary/private — never push its curriculum into public teachy-app.
- Do not force-push, do not change git config, do not delete unrelated folders.
```

**Adding a feature?** [HOW-TO-ADD-A-FEATURE.md](HOW-TO-ADD-A-FEATURE.md) — which layer, which tests, what not to break.

**Start querying:** [QUERYING.md](QUERYING.md)

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
| [0007](decisions/0007-the-brain-maintains-itself.md) | The brain maintains itself |
| [0008](decisions/0008-telemetry-is-local-first.md) | Telemetry is local-first, and grades the decisions |
| [0009](decisions/0009-gbrain-indexes-the-brain.md) | gbrain indexes the brain (reversing part of 0006) |
| [0010](decisions/0010-public-surfaces-leave-old-repo.md) | Public surfaces leave the old repo; appcast stays |
| [0011](decisions/0011-mac-ships-electron-react.md) | Mac ships the Electron/React shell too |
| [0012](decisions/0012-own-am-openclaw-ai-fluency.md) | Own A&M with OpenClaw-grade AI fluency coaching |
| [0013](decisions/0013-teachy-agent-runtime.md) | Teachy agent runtime — OpenClaw for AI fluency |
| [0014](decisions/0014-teachy-shows-never-acts.md) | Teachy shows; never does it for them |
| [0015](decisions/0015-borrow-a-subscription-over-acp.md) | Borrow a Claude Pro / ChatGPT subscription over ACP |
| [0016](decisions/0016-b2b-desktop-had-never-been-built.md) | B2B desktop had never been built |
| [0017](decisions/0017-one-engine-two-editions.md) | One engine, two editions (B2C OSS / B2B closed) |
| [0018](decisions/0018-b2b-proprietary-publish-wipe-swift.md) | B2B proprietary; publish Electron; wipe Swift |
| [0019](decisions/0019-comic-visual-language-on-teachy-web.md) | Comic visual language on teachy-web |

## Keeping itself honest

Nobody maintains this by hand:

| Check | What it does |
|-------|--------------|
| `hooks/post-commit` | rebuilds the graph, detached, after every commit |
| `hooks/pre-push` | warns if the brain is drifting as work leaves the machine |
| `scripts/brain-status.ps1` | one exit code: graph freshness, unfilled records, drifted index, code shipping while the brain stays still |
| `scripts/graph-status.ps1` | is the graph built from the current HEADs? |
| `scripts/new-decision.ps1` | scaffolds a record with the right shape and number |
| `scripts/telemetry-report.ps1` | grades decisions 0001/0002/0004 against what actually happened |
| `scripts/dream.ps1` | gathers a reflective briefing — see [DREAMING.md](DREAMING.md) |

Agents are told to write back in every repo's `CLAUDE.md`. The protocol —
including when *not* to record — is [WRITE-BACK.md](WRITE-BACK.md).

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
| **teachy-app** | Electron engine (`packages/core`) + free B2C (`apps/b2c`) + Windows sidecar — MIT, public |
| **teachy-b2b** | Workplace edition only — proprietary, private |
| **teachy-web** | the Academy site and its deploy config |
| **teachy-brain** (this one) | strategy, decisions, incidents, launch, course design |
