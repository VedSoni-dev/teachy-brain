<#
.SYNOPSIS
  Points all three Teachy repos at the shared, version-controlled git hooks.

.DESCRIPTION
  Sets core.hooksPath in each repo to teachy-brain/hooks. That directory is
  committed, so the hooks are reviewed like any other code instead of living
  untracked in .git/hooks where they silently differ between machines and
  disappear on a fresh clone.

  core.hooksPath is local config and is not cloned, so bootstrap.ps1 calls this.
  Re-running is safe.

.EXAMPLE
  pwsh teachy-brain/scripts/install-hooks.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path
$hooksDirectory = Join-Path (Join-Path $workspaceRoot 'teachy-brain') 'hooks'
$repoNames = @('teachy-app', 'teachy-web', 'teachy-brain')

if (-not (Test-Path $hooksDirectory)) {
    throw "No hooks directory at $hooksDirectory"
}

# Git wants forward slashes in config values, on every platform.
$hooksPathValue = $hooksDirectory -replace '\\', '/'

foreach ($repoName in $repoNames) {
    $repoPath = Join-Path $workspaceRoot $repoName
    if (-not (Test-Path (Join-Path $repoPath '.git'))) {
        Write-Warning "skipping $repoName - not a git repo at $repoPath"
        continue
    }

    git -C $repoPath config core.hooksPath $hooksPathValue
    Write-Host "  $repoName -> $hooksPathValue" -ForegroundColor Green
}

# Git for Windows needs the executable bit in the index for hooks to run.
$postCommitHook = Join-Path $hooksDirectory 'post-commit'
if (Test-Path $postCommitHook) {
    $brainPath = Join-Path $workspaceRoot 'teachy-brain'
    git -C $brainPath update-index --chmod=+x hooks/post-commit 2>$null
}

Write-Host ''
Write-Host 'Hooks installed. Every commit now rebuilds the knowledge graph in the background.' -ForegroundColor Green
Write-Host 'Check freshness any time: pwsh teachy-brain/scripts/graph-status.ps1'
