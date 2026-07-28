# Set up Teachy on a new machine

Three repos, one workspace, one command.

## The paste-into-an-agent prompt

Open Claude Code (or any coding agent) in the folder where you want Teachy to
live, and paste this:

```
Set up my Teachy workspace here.

Clone VedSoni-dev/teachy-brain, then run its scripts/bootstrap.ps1 on Windows or
scripts/bootstrap.sh on macOS. That creates a teachy/ folder with all three
repos (teachy-app, teachy-web, teachy-brain), installs dependencies, builds the
C# sidecar, runs the full test suite, and builds the cross-repo knowledge graph.

The repos are private, so `gh auth login` first if gh is not authenticated.

When it finishes, read teachy-brain/QUERYING.md and tell me what state the
workspace is in — anything that failed, anything skipped, and what is worth
doing next according to teachy-brain/engineering/known-issues.md.
```

## Or just run it

**Windows**

```powershell
gh repo clone VedSoni-dev/teachy-brain
powershell -ExecutionPolicy Bypass -File teachy-brain\scripts\bootstrap.ps1
```

**macOS / Linux**

```bash
gh repo clone VedSoni-dev/teachy-brain
bash teachy-brain/scripts/bootstrap.sh
```

Both are re-runnable. On a second run they pull instead of cloning, so this is
also how you refresh a workspace that has gone stale.

## What you need first

| Tool | Why | Install |
|------|-----|---------|
| `git` | obviously | comes with Xcode CLT / Git for Windows |
| `gh`, authenticated | **the repos are private** | `winget install GitHub.cli` / `brew install gh`, then `gh auth login` |
| `node` | the Windows app and its tests | `winget install OpenJS.NodeJS.LTS` / `brew install node` |
| `dotnet` 8 | the C# sidecar — required on Windows, optional on macOS | `winget install Microsoft.DotNet.SDK.8` |
| `graphify` | the knowledge graph — optional, but it is the query layer | `pip install graphify` |

The scripts check all of these up front and report every missing one at once,
rather than dying on the first and making you run it five times.

## What you end up with

```
teachy/
  teachy-app/     macOS + Windows apps, courses, connectors, worker
  teachy-web/     the Academy site
  teachy-brain/   decisions, architecture, incidents, launch
  graph/          teachy-graph.json — the cross-repo knowledge graph
```

Then:

```bash
cd teachy-app/desktop && npm start        # run the Windows app
cd teachy-app/desktop && npm run verify   # build + test everything
graphify explain "MicrophoneRecorder" --graph graph/teachy-graph.json
```

## The one thing that will bite you

On macOS the C# sidecar does not build — it is Windows-only (UI Automation,
DPAPI, SAPI). The bootstrap notices and skips it rather than failing, so on a Mac
you get the renderer tests but not the sidecar tests. The Mac app itself is the
Xcode project in `teachy-app/`.
