<#
.SYNOPSIS
  Rebuilds the Teachy company knowledge graph across all three repos.

.DESCRIPTION
  The graph is a VIEW, never a source. Everything it knows comes from markdown
  and code that is committed somewhere; if the graph is wrong, delete
  graphify-out/ and run this again. Nothing is lost, because nothing is stored
  here that is not stored in git first. See decisions/0006.

  Run this after any meaningful change — a new decision record, a refactor, a
  new incident. It takes about a minute.

.EXAMPLE
  pwsh teachy-brain/scripts/rebuild-graph.ps1
#>

$ErrorActionPreference = 'Stop'

# The workspace root is the parent of teachy-brain — where all three repos live.
# Nested Join-Path rather than the multi-argument form: Windows PowerShell 5.1
# only accepts -Path and -ChildPath, and this has to run on a stock Windows box.
$workspaceRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path
$repoNames = @('teachy-app', 'teachy-web', 'teachy-brain')
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

Write-Host ""
Write-Host "Company graph: $mergedGraphPath" -ForegroundColor Green
Write-Host 'Ask it something:' -ForegroundColor Green
Write-Host "  graphify explain `"MicrophoneRecorder`" --graph `"$mergedGraphPath`""
