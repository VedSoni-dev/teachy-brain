<#
.SYNOPSIS
  Rebuilds the Teachy company knowledge graph across every repo in the workspace.

.DESCRIPTION
  The graph is a VIEW, never a source. Everything it knows comes from markdown
  and code that is committed somewhere; if the graph is wrong, delete
  graphify-out/ and run this again. Nothing is lost, because nothing is stored
  here that is not stored in git first. See decisions/0006.

  Run this after any meaningful change - a new decision record, a refactor, a
  new incident. It takes about a minute.

.EXAMPLE
  pwsh teachy-brain/scripts/rebuild-graph.ps1
#>

$ErrorActionPreference = 'Stop'

# The workspace root is the parent of teachy-brain - where the repos live.
# Nested Join-Path rather than the multi-argument form: Windows PowerShell 5.1
# only accepts -Path and -ChildPath, and this has to run on a stock Windows box.
$workspaceRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path

# teachy-b2b is included but optional - the loop below skips repos that are not
# checked out, so a B2C-only workspace still gets a graph. The merged graph is
# gitignored and never leaves the machine, so indexing the proprietary edition
# here does not publish it. See decisions/0018.
$repoNames = @('teachy-app', 'teachy-b2b', 'teachy-web', 'teachy-brain')
$mergedGraphDirectory = Join-Path $workspaceRoot 'graph'
$mergedGraphPath = Join-Path $mergedGraphDirectory 'teachy-graph.json'

if (-not (Get-Command graphify -ErrorAction SilentlyContinue)) {
    throw "graphify is not on PATH. Install it, then re-run: pip install graphify"
}

$graphPaths = @()
foreach ($repoName in $repoNames) {
    $repoPath = Join-Path $workspaceRoot $repoName
    if (-not (Test-Path $repoPath)) {
        Write-Warning "skipping $repoName - not found at $repoPath"
        continue
    }

    Write-Host "rebuilding $repoName..." -ForegroundColor Cyan
    graphify update $repoPath | Select-Object -Last 1

    $repoGraphPath = Join-Path $repoPath 'graphify-out\graph.json'
    if (Test-Path $repoGraphPath) {
        $graphPaths += $repoGraphPath
    } else {
        Write-Warning "$repoName produced no graph.json"
    }
}

if ($graphPaths.Count -eq 0) {
    throw 'No repo graphs were produced - nothing to merge.'
}

New-Item -ItemType Directory -Force $mergedGraphDirectory | Out-Null
Write-Host "merging $($graphPaths.Count) graphs..." -ForegroundColor Cyan
graphify merge-graphs @graphPaths --out $mergedGraphPath | Select-Object -Last 1

# Stamp which commit of each repo this graph was built from.
#
# Without this, "is the graph current?" can only be guessed from file timestamps,
# which lie in both directions - a rebuild that changed nothing looks fresh, and
# a clone with fresh mtimes looks current when it was never built at all.
# Recording the HEAD SHAs makes staleness a fact rather than an inference, and it
# is what scripts/graph-status.ps1 checks.
$builtFrom = [ordered]@{}
foreach ($repoName in $repoNames) {
    $repoPath = Join-Path $workspaceRoot $repoName
    if (Test-Path $repoPath) {
        $headSha = (git -C $repoPath rev-parse HEAD 2>$null)
        if ($LASTEXITCODE -eq 0) { $builtFrom[$repoName] = $headSha.Trim() }
    }
}

# Keep gbrain's corpus current too.
#
# gbrain indexes the markdown - decisions, incidents, architecture - and answers
# semantic questions ("why did we choose X") that a structural graph cannot.
# It is a VIEW over the same git-backed markdown, exactly like the graph, so it
# rebuilds on the same trigger. An index nobody refreshes answers confidently
# from a world that stopped existing, which is worse than having no index.
#
# Best-effort: gbrain is optional. A machine without it still gets the graph.
if (Get-Command gbrain -ErrorAction SilentlyContinue) {
    foreach ($repoName in $repoNames) {
        $repoPath = Join-Path $workspaceRoot $repoName
        if (-not (Test-Path $repoPath)) { continue }

        # $ErrorActionPreference='Stop' turns ANY native stderr output into a
        # terminating error, and gbrain writes routine routing notices there. The
        # first version of this reported "import failed" on three successful
        # imports. Judge the exit code, not the stream.
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $importOutput = & gbrain import $repoPath --no-embed 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "gbrain import failed for ${repoName} (exit $LASTEXITCODE)"
            } else {
                $importedLine = ($importOutput -split "`n" | Where-Object { $_ -match 'pages imported' } | Select-Object -First 1)
                if ($importedLine) { Write-Host "  gbrain ${repoName}:$($importedLine.TrimEnd())" }
            }
        } finally {
            $ErrorActionPreference = $previousPreference
        }
    }
} else {
    Write-Host 'gbrain not installed - skipping semantic index.' -ForegroundColor DarkGray
}

$metadataPath = Join-Path $mergedGraphDirectory 'teachy-graph.meta.json'
[ordered]@{
    builtAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    builtFrom  = $builtFrom
} | ConvertTo-Json -Depth 5 | Set-Content -Path $metadataPath -Encoding utf8

Write-Host ""
Write-Host "Company graph: $mergedGraphPath" -ForegroundColor Green
Write-Host 'Ask it something:' -ForegroundColor Green
Write-Host "  graphify explain `"MicrophoneRecorder`" --graph `"$mergedGraphPath`""
