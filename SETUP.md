# Set up Teachy on a new machine

Electron engine. Mac and Windows. No Swift / Xcode.

## Paste into Claude Code (any OS)

Open Claude Code in the folder where you want the workspace, and paste:

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
   ```
   teachy/
     teachy-app/    # public — engine + B2C
     teachy-web/
     teachy-brain/
     teachy-b2b/    # private — skip if no access
   ```
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

## Or run bootstrap yourself

**Windows**

```powershell
gh repo clone VedSoni-dev/teachy-brain
pwsh -ExecutionPolicy Bypass -File teachy-brain\scripts\bootstrap.ps1
```

**macOS / Linux**

```bash
gh repo clone VedSoni-dev/teachy-brain
bash teachy-brain/scripts/bootstrap.sh
```

Re-runnable: second run pulls instead of cloning.

## What you need first

| Tool | Why | Install |
|------|-----|---------|
| `git` | clone | Git for Windows / Xcode CLT |
| `gh` | clone + private B2B check | `winget install GitHub.cli` / `brew install gh` |
| `node` 18+ | Electron + tests | `winget install OpenJS.NodeJS.LTS` / `brew install node` |
| `dotnet` 8 | Windows sidecar | `winget install Microsoft.DotNet.SDK.8` (required on Windows) |
| `pwsh` | brain scripts | optional on Mac: `brew install --cask powershell` |
| `graphify` | knowledge graph | optional: `pip install graphifyy` |

## What you end up with

```
teachy/
  teachy-app/     packages/core + apps/b2c + windows/ sidecar
  teachy-web/     Academy site
  teachy-brain/   decisions, known issues, this SETUP
  teachy-b2b/     workplace edition (if granted)
  graph/          teachy-graph.json (when graphify ran)
```

```bash
cd teachy-app && npm run start      # free edition
cd teachy-app && npm run verify
cd teachy-b2b && npm run start      # if present
```

## The one thing that will bite you

`npm run verify` can pass **without** the Electron binary when npm blocks
install scripts. The app then dies at launch. Always run
`npm approve-scripts electron` (see `teachy-app/INTERN.md`).
