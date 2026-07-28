<#
.SYNOPSIS
  Reports whether the company knowledge graph still matches the repos.

.DESCRIPTION
  Silent rot is the failure mode this whole system is most exposed to: a graph
  that answers confidently from a state of the world that stopped being true
  three weeks ago. Nothing about a stale graph looks broken - it just quietly
  starts lying.

  So staleness is a checkable fact, not a vibe. rebuild-graph.ps1 records the
  HEAD SHA of every repo it built from; this compares those against the repos
  now.

.PARAMETER Quiet
  Print nothing; communicate only through the exit code. For hooks and CI.

.OUTPUTS
  Exit 0 - the graph is current.
  Exit 1 - the graph is stale, missing, or was never built.

.EXAMPLE
  pwsh teachy-brain/scripts/graph-status.ps1
#>

[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path
$metadataPath = Join-Path (Join-Path $workspaceRoot 'graph') 'teachy-graph.meta.json'
$graphPath = Join-Path (Join-Path $workspaceRoot 'graph') 'teachy-graph.json'

function Report($message, $color) { if (-not $Quiet) { Write-Host $message -ForegroundColor $color } }

if (-not (Test-Path $graphPath) -or -not (Test-Path $metadataPath)) {
    Report 'Graph has never been built.' Yellow
    Report '  Fix: pwsh teachy-brain/scripts/rebuild-graph.ps1' Yellow
    exit 1
}

$metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
$staleRepos = @()

foreach ($repoProperty in $metadata.builtFrom.PSObject.Properties) {
    $repoName = $repoProperty.Name
    $builtFromSha = $repoProperty.Value
    $repoPath = Join-Path $workspaceRoot $repoName

    if (-not (Test-Path $repoPath)) {
        $staleRepos += "$repoName (missing from the workspace)"
        continue
    }

    $currentSha = (git -C $repoPath rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0) { continue }
    $currentSha = $currentSha.Trim()

    if ($currentSha -ne $builtFromSha) {
        # How far behind, in commits the graph has never seen.
        $behindCount = (git -C $repoPath rev-list --count "$builtFromSha..$currentSha" 2>$null)
        $behindText = if ($LASTEXITCODE -eq 0 -and $behindCount) { "$($behindCount.Trim()) commits behind" } else { 'out of sync' }
        $staleRepos += "$repoName ($behindText)"
    }
}

$builtAt = [datetime]::Parse($metadata.builtAtUtc).ToLocalTime()

if ($staleRepos.Count -eq 0) {
    Report "Graph is current (built $($builtAt.ToString('yyyy-MM-dd HH:mm')))." Green
    exit 0
}

Report "Graph is STALE (built $($builtAt.ToString('yyyy-MM-dd HH:mm'))):" Yellow
foreach ($staleRepo in $staleRepos) { Report "  - $staleRepo" Yellow }
Report '  Fix: pwsh teachy-brain/scripts/rebuild-graph.ps1' Yellow
exit 1
