<#
.SYNOPSIS
  The gathering half of a dream cycle - collects everything a reflective pass
  needs to reason over.

.DESCRIPTION
  Modelled on gbrain's dream cycle, which runs mechanical phases (extract_atoms,
  resolve_symbol_edges) and only then consolidates. The split is the useful part:
  a machine can find the CANDIDATES for rot cheaply and exhaustively, but only a
  reader can tell whether two records actually contradict each other, or whether
  a claim has quietly stopped being true.

  So this does the mechanical half and writes a briefing. The reflective half is
  done by Claude against that briefing - see DREAMING.md.

  Nothing here writes to the brain. Gathering must never mutate what it measures.

.PARAMETER OutputPath
  Where to write the briefing. Defaults to graph/dream-input.md (gitignored).

.EXAMPLE
  pwsh teachy-brain/scripts/dream.ps1
#>

[CmdletBinding()]
param([string]$OutputPath)

$ErrorActionPreference = 'Stop'

$brainRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = (Resolve-Path (Join-Path $brainRoot '..')).Path
if (-not $OutputPath) {
    $OutputPath = Join-Path (Join-Path $workspaceRoot 'graph') 'dream-input.md'
}
New-Item -ItemType Directory -Force (Split-Path $OutputPath) | Out-Null

$report = [System.Collections.Generic.List[string]]::new()
function Emit($line) { $report.Add([string]$line) }

Emit '# Dream briefing'
Emit ''
Emit "Generated $((Get-Date).ToString('yyyy-MM-dd HH:mm')). Mechanical findings only -"
Emit 'every item below is a CANDIDATE needing a judgement call, not a defect.'
Emit ''

# -- Phase 1: what changed since the last dream --------------------------------

$lastDreamMarker = Join-Path (Join-Path $workspaceRoot 'graph') '.last-dream'
$sinceArgument = $null
if (Test-Path $lastDreamMarker) {
    $sinceArgument = (Get-Content $lastDreamMarker -Raw).Trim()
    Emit "## Since the last dream ($sinceArgument)"
} else {
    Emit '## Since the beginning (no previous dream)'
}
Emit ''

foreach ($repoName in @('teachy-app', 'teachy-web', 'teachy-brain')) {
    $repoPath = Join-Path $workspaceRoot $repoName
    if (-not (Test-Path $repoPath)) { continue }

    $logArguments = @('-C', $repoPath, 'log', '--oneline', '--no-merges')
    if ($sinceArgument) { $logArguments += "--since=$sinceArgument" }
    $commits = @(& git @logArguments 2>$null)

    if ($commits.Count -eq 0) {
        Emit "- **$repoName**: nothing new"
    } else {
        Emit "- **$repoName**: $($commits.Count) commits"
        foreach ($commit in ($commits | Select-Object -First 25)) { Emit "  - $commit" }
        if ($commits.Count -gt 25) { Emit "  - ... and $($commits.Count - 25) more" }
    }
}
Emit ''

# -- Phase 2: claims nothing has checked ---------------------------------------
#
# Every decision record says "revisit when X". Nobody re-reads them, so those
# conditions stay invisible until someone goes looking. Surfacing them is the
# highest-value thing a dream cycle does.

Emit '## Revisit conditions (are any now true?)'
Emit ''
$decisionsDirectory = Join-Path $brainRoot 'decisions'
foreach ($decisionFile in (Get-ChildItem $decisionsDirectory -Filter '*.md' -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $inRevisitSection = $false
    $revisitLines = @()
    # -Encoding UTF8 is not optional: Windows PowerShell 5.1 reads as ANSI by
    # default, so every em-dash in a record came through as mojibake and the
    # briefing quoted our own writing back at us corrupted.
    foreach ($line in (Get-Content $decisionFile.FullName -Encoding UTF8)) {
        if ($line -match '^##\s+Revisit when') { $inRevisitSection = $true; continue }
        if ($inRevisitSection -and $line -match '^##\s') { break }
        if ($inRevisitSection -and $line.Trim().Length -gt 0) { $revisitLines += $line.Trim() }
    }
    if ($revisitLines.Count -gt 0) {
        Emit "### $($decisionFile.BaseName)"
        foreach ($revisitLine in $revisitLines) { Emit "  $revisitLine" }
        Emit ''
    }
}

# -- Phase 3: age --------------------------------------------------------------

Emit '## Age of each record'
Emit ''
Emit 'Old is not wrong. But a record written before a rewrite it never mentions is'
Emit 'worth re-reading.'
Emit ''
$markdownFiles = Get-ChildItem $brainRoot -Recurse -Filter '*.md' -File |
    Where-Object { $_.FullName -notmatch 'graphify-out' }
foreach ($markdownFile in $markdownFiles) {
    $relativePath = $markdownFile.FullName.Substring($brainRoot.Length + 1)
    $lastCommitDate = (& git -C $brainRoot log -1 --format=%cs -- $relativePath 2>$null)
    if ($lastCommitDate) {
        $ageDays = ((Get-Date) - [datetime]$lastCommitDate).Days
        Emit ("- {0,-58} {1,4}d" -f $relativePath, $ageDays)
    }
}
Emit ''

# -- Phase 4: what the numbers say ---------------------------------------------

Emit '## Telemetry'
Emit ''
$telemetryScript = Join-Path (Join-Path $brainRoot 'scripts') 'telemetry-report.ps1'
if (Test-Path $telemetryScript) {
    $telemetryOutput = (& $telemetryScript 2>&1 | Out-String).Trim()
    Emit '```'
    Emit $telemetryOutput
    Emit '```'
} else {
    Emit '(no telemetry-report.ps1)'
}
Emit ''

# -- Phase 5: structural health ------------------------------------------------

Emit '## Brain health'
Emit ''
$brainStatusScript = Join-Path (Join-Path $brainRoot 'scripts') 'brain-status.ps1'
$brainStatusOutput = (& $brainStatusScript 2>&1 | Out-String).Trim()
Emit '```'
Emit $brainStatusOutput
Emit '```'
Emit ''

# -- Phase 6: the questions ----------------------------------------------------

Emit '## Now reflect'
Emit ''
Emit 'Read the above and answer these. Each has a concrete output.'
Emit ''
Emit '1. **Any revisit condition now met?** -> update that record, or write a new'
Emit '   one superseding it. Say which and why.'
Emit '2. **Do any two records contradict each other?** -> the newer wins; mark the'
Emit '   older `Status: superseded by NNNN` rather than deleting it.'
Emit '3. **Did anything in the commits make a claim untrue?** -> fix the claim. A'
Emit '   confidently wrong record is worse than a missing one.'
Emit '4. **Is anything in known-issues.md actually fixed?** -> move it to the fixed'
Emit '   table, keeping the reasoning that is worth having.'
Emit '5. **Did work happen with no record of the reasoning?** -> new decision record.'
Emit '6. **Anything worth promoting into persistent memory** (a durable fact about'
Emit '   Ved, the project, or how to work on it)? -> write the memory file.'
Emit ''
Emit 'When done, stamp the cycle:'
Emit '```'
Emit '  (Get-Date).ToString("o") | Set-Content graph/.last-dream'
Emit '```'

Set-Content -Path $OutputPath -Value ($report -join "`n") -Encoding utf8

Write-Host "Dream briefing: $OutputPath" -ForegroundColor Green
Write-Host 'Read it, act on the six questions, then stamp graph/.last-dream.' -ForegroundColor Cyan
