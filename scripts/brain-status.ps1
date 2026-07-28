<#
.SYNOPSIS
  One health check for the whole company brain.

.DESCRIPTION
  A brain rots in ways that never throw an error. The graph drifts from the code.
  A decision record gets scaffolded and never filled in. The README stops listing
  half the decisions. Known issues describe a version nobody runs any more.

  Every one of those still *reads* fine - which is the problem. Confident, wrong
  answers are worse than no answers, because nobody goes to check.

  This makes each of those a check with an exit code, so rot is something that
  gets reported rather than discovered.

.PARAMETER Quiet
  Print only problems. For hooks and scheduled runs.

.OUTPUTS
  Exit 0 - healthy.
  Exit 1 - at least one problem worth fixing.

.EXAMPLE
  pwsh teachy-brain/scripts/brain-status.ps1
#>

[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

$brainRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = (Resolve-Path (Join-Path $brainRoot '..')).Path

$problems = @()
$notes = @()

function Say($message, $color = 'Gray') { if (-not $Quiet) { Write-Host $message -ForegroundColor $color } }

# -- 1. Is the graph current? --------------------------------------------------

$graphStatusScript = Join-Path (Join-Path $brainRoot 'scripts') 'graph-status.ps1'
& $graphStatusScript -Quiet
if ($LASTEXITCODE -eq 0) {
    $notes += 'graph is current'
} else {
    $problems += 'Graph is stale or missing. Fix: pwsh teachy-brain/scripts/rebuild-graph.ps1'
}

# -- 2. Decision records that were scaffolded and abandoned --------------------
#
# new-decision.ps1 leaves <angle-bracket prompts> in every section. A record
# still carrying them is a placeholder masquerading as a decision - worse than
# nothing, because it looks answered.

$decisionsDirectory = Join-Path $brainRoot 'decisions'
$decisionFiles = @(Get-ChildItem $decisionsDirectory -Filter '*.md' -ErrorAction SilentlyContinue)

foreach ($decisionFile in $decisionFiles) {
    $content = Get-Content $decisionFile.FullName -Raw
    if ($content -match '<[a-zA-Z][^>]{20,}>') {
        $problems += "Decision $($decisionFile.Name) still has unfilled template sections."
    }
    if ($content -notmatch '(?im)^##\s+What it costs us') {
        $problems += "Decision $($decisionFile.Name) has no 'What it costs us' section."
    }
}
$notes += "$($decisionFiles.Count) decision records"

# -- 2b. Claims the evidence could settle but nobody has ------------------------
#
# Added because 0007's own revisit condition fired: "telemetry exists, at which
# point decision records should carry an outcome". A record that states a belief
# forever, while the data that would confirm or kill it sits unread in a log
# file, is the failure 0008 exists to prevent.

$teachyHome = if ($env:TEACHY_HOME) { $env:TEACHY_HOME } else { Join-Path $env:USERPROFILE '.teachy' }
$eventLogPath = Join-Path $teachyHome 'events.jsonl'
$hasEvidence = (Test-Path $eventLogPath) -and ((Get-Item $eventLogPath).Length -gt 0)

if ($hasEvidence) {
    $ungraded = @()
    foreach ($decisionFile in $decisionFiles) {
        $content = Get-Content $decisionFile.FullName -Raw -Encoding UTF8
        if ($content -match '(?im)^##\s+Outcome' -and $content -match '(?im)Not yet measured') {
            $ungraded += $decisionFile.BaseName
        }
    }
    if ($ungraded.Count -gt 0) {
        $problems += "There is telemetry, but $($ungraded.Count) record(s) are still ungraded: $($ungraded -join ', '). Run telemetry-report.ps1 and fill in their Outcome."
    } else {
        $notes += 'telemetry exists and no record is left ungraded'
    }
} else {
    $notes += 'no telemetry yet (nothing to grade against)'
}

# -- 3. Does the README still list every decision? -----------------------------

$readmePath = Join-Path $brainRoot 'README.md'
if (Test-Path $readmePath) {
    $readmeContent = Get-Content $readmePath -Raw
    foreach ($decisionFile in $decisionFiles) {
        if ($readmeContent -notmatch [regex]::Escape($decisionFile.Name)) {
            $problems += "README does not link $($decisionFile.Name) - the index has drifted."
        }
    }
}

# -- 4. Has anything shipped since the brain last learned something? -----------
#
# The signal that matters: lots of code landing while the brain stays still means
# decisions are being made and lost.

$brainLastCommit = [datetime](git -C $brainRoot log -1 --format=%cI 2>$null)
$appRoot = Join-Path $workspaceRoot 'teachy-app'

if (Test-Path $appRoot) {
    $appCommitsSinceBrain = (git -C $appRoot rev-list --count --since="$($brainLastCommit.ToString('o'))" HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and [int]$appCommitsSinceBrain -ge 10) {
        $problems += "$appCommitsSinceBrain commits landed in teachy-app since the brain last learned anything. Decisions are probably being lost."
    } else {
        $notes += "$appCommitsSinceBrain app commits since the brain last changed"
    }
}

# -- 5. Are known issues being maintained? -------------------------------------

$knownIssuesPath = Join-Path (Join-Path $brainRoot 'engineering') 'known-issues.md'
if (Test-Path $knownIssuesPath) {
    $lastTouched = [datetime](git -C $brainRoot log -1 --format=%cI -- engineering/known-issues.md 2>$null)
    $daysSince = ((Get-Date) - $lastTouched).Days
    if ($daysSince -gt 30) {
        $problems += "known-issues.md has not been touched in $daysSince days. Either nothing broke, or nobody wrote it down."
    } else {
        $notes += "known issues updated $daysSince days ago"
    }
} else {
    $problems += 'engineering/known-issues.md is missing.'
}

# -- Report --------------------------------------------------------------------

if ($problems.Count -eq 0) {
    Say 'Brain is healthy.' Green
    foreach ($note in $notes) { Say "  - $note" DarkGray }
    exit 0
}

Write-Host "Brain needs attention ($($problems.Count)):" -ForegroundColor Yellow
foreach ($problem in $problems) { Write-Host "  - $problem" -ForegroundColor Yellow }
if (-not $Quiet -and $notes.Count -gt 0) {
    Write-Host 'Healthy:' -ForegroundColor DarkGray
    foreach ($note in $notes) { Write-Host "  - $note" -ForegroundColor DarkGray }
}
exit 1
