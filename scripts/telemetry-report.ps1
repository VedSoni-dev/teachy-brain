<#
.SYNOPSIS
  Grades decision records against what actually happened.

.DESCRIPTION
  Every decision record states what we believed. Until now nothing checked
  whether we were right, so the brain could be perfectly maintained and
  perfectly wrong - which is a worse failure than an out-of-date wiki, because
  it is confident.

  This reads the local event log the app writes and answers the specific
  questions the decision records left open:

    0002 - which key-setup step leaks?
    0004 - does anyone finish the flagship course?
    0001 - what actually goes wrong for people, and how often?

  Local only. It reads one machine's log, which is the founder's or a
  dogfooder's. It is not a fleet metric and must not be reported as one.

.PARAMETER EventLogPath
  Override the log location. Defaults to $env:TEACHY_HOME\events.jsonl, or
  ~/.teachy/events.jsonl.

.EXAMPLE
  pwsh teachy-brain/scripts/telemetry-report.ps1
#>

[CmdletBinding()]
param([string]$EventLogPath)

$ErrorActionPreference = 'Stop'

if (-not $EventLogPath) {
    $teachyHome = if ($env:TEACHY_HOME) { $env:TEACHY_HOME } else { Join-Path $env:USERPROFILE '.teachy' }
    $EventLogPath = Join-Path $teachyHome 'events.jsonl'
}

if (-not (Test-Path $EventLogPath)) {
    Write-Host "No event log at $EventLogPath" -ForegroundColor Yellow
    Write-Host 'Nothing has been measured yet. Run the app, and this fills in.' -ForegroundColor Yellow
    exit 0
}

$events = @(
    Get-Content $EventLogPath |
        Where-Object { $_.Trim().Length -gt 0 } |
        ForEach-Object {
            # One malformed line must not take the whole report down - a partial
            # write during a crash is exactly when you most want the report.
            try { $_ | ConvertFrom-Json } catch { $null }
        } |
        Where-Object { $_ -ne $null }
)

if ($events.Count -eq 0) {
    Write-Host 'Event log is empty.' -ForegroundColor Yellow
    exit 0
}

function CountOf($eventName) { @($events | Where-Object { $_.event -eq $eventName }).Count }

$firstAt = [datetime]::Parse($events[0].at).ToLocalTime()
$lastAt = [datetime]::Parse($events[-1].at).ToLocalTime()

Write-Host ''
Write-Host 'TEACHY - what actually happened' -ForegroundColor Cyan
Write-Host "  $($events.Count) events, $($firstAt.ToString('yyyy-MM-dd HH:mm')) to $($lastAt.ToString('yyyy-MM-dd HH:mm'))"
Write-Host "  Source: $EventLogPath (this machine only)" -ForegroundColor DarkGray

# -- Decision 0002: which key-setup step leaks? --------------------------------

Write-Host ''
Write-Host 'Key setup  (grades decision 0002)' -ForegroundColor Cyan

$setupShown = CountOf 'key_setup_shown'
$setupCompleted = CountOf 'key_setup_completed'
$setupDismissed = CountOf 'key_setup_abandoned'

# Quitting is DERIVED, not measured.
#
# The "I'll do this later" button fires an event. Closing the app does not - the
# unmount handler never runs on a hard quit, verified by killing the process
# mid-setup and watching nothing appear. Since closing the app is the most
# common way to abandon anything, trusting the event alone would have reported
# near-zero abandonment and looked like a triumph. Shown minus completed minus
# dismissed is the honest number.
$setupQuit = [math]::Max(0, $setupShown - $setupCompleted - $setupDismissed)

if ($setupShown -eq 0) {
    Write-Host '  never shown' -ForegroundColor DarkGray
} else {
    $completionRate = [math]::Round(100 * $setupCompleted / $setupShown)
    Write-Host "  shown $setupShown, completed $setupCompleted ($completionRate%)"
    Write-Host "  dismissed ('later') $setupDismissed, quit without finishing $setupQuit"

    if ($setupDismissed -gt 0) {
        Write-Host "  dismissed at:" -ForegroundColor Yellow
        $events |
            Where-Object { $_.event -eq 'key_setup_abandoned' } |
            Group-Object step | Sort-Object Count -Descending |
            ForEach-Object { Write-Host "    $($_.Name): $($_.Count)" -ForegroundColor Yellow }
    }

    # For quitters the last step they touched is all we know, and it is enough
    # to say which screen loses people.
    if ($setupQuit -gt 0) {
        $furthestStep = @($events | Where-Object { $_.event -eq 'key_setup_step' })[-1].step
        Write-Host "  furthest step reached in the last attempt: $furthestStep" -ForegroundColor Yellow
    }

    $validations = @($events | Where-Object { $_.event -eq 'key_setup_validation' })
    if ($validations.Count -gt 0) {
        Write-Host '  key checks:'
        $validations | Group-Object outcome | Sort-Object Count -Descending | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Count)"
        }
    }

    $clipboardHits = CountOf 'key_setup_clipboard_hit'
    $clipboardMisses = CountOf 'key_setup_clipboard_miss'
    if (($clipboardHits + $clipboardMisses) -gt 0) {
        Write-Host "  clipboard offer: $clipboardHits hit, $clipboardMisses miss"
    }

    # Time on step says where people are stuck rather than merely where they are.
    $stepDurations = $events | Where-Object { $_.event -eq 'key_setup_step' -and $_.durationMs -gt 0 }
    if ($stepDurations) {
        Write-Host '  median seconds on step:'
        $stepDurations | Group-Object step | ForEach-Object {
            $sorted = @($_.Group.durationMs | Sort-Object)
            $median = $sorted[[math]::Floor($sorted.Count / 2)]
            Write-Host "    $($_.Name): $([math]::Round($median / 1000, 1))s"
        }
    }
}

# -- Decision 0004: does the flagship get finished? ----------------------------

Write-Host ''
Write-Host 'Flagship course  (grades decision 0004)' -ForegroundColor Cyan

$coursesStarted = CountOf 'course_started'
$coursesCompleted = CountOf 'course_completed'

if ($coursesStarted -eq 0) {
    Write-Host '  never started' -ForegroundColor DarkGray
} else {
    $finishRate = [math]::Round(100 * $coursesCompleted / $coursesStarted)
    Write-Host "  started $coursesStarted, completed $coursesCompleted ($finishRate%)"

    $exits = @($events | Where-Object { $_.event -eq 'course_exited' })
    if ($exits.Count -gt 0) {
        Write-Host '  quit at goal:' -ForegroundColor Yellow
        $exits | Group-Object goalId | Sort-Object Count -Descending | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Count)" -ForegroundColor Yellow
        }
    }

    $verifications = @($events | Where-Object { $_.event -eq 'course_goal_verified' })
    if ($verifications.Count -gt 0) {
        Write-Host '  verification outcomes:'
        $verifications | Group-Object outcome | Sort-Object Count -Descending | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Count)"
        }

        # checkFailed is OUR fault, not the learner's. If it is a meaningful
        # slice, people are being told "not quite" for our outages.
        $checkFailed = @($verifications | Where-Object { $_.outcome -eq 'checkFailed' }).Count
        if ($checkFailed -gt 0) {
            $checkFailedRate = [math]::Round(100 * $checkFailed / $verifications.Count)
            Write-Host "    -> $checkFailedRate% of checks failed on our side, not the learner's" -ForegroundColor Yellow
        }
    }

    $hintCount = CountOf 'course_hint_requested'
    if ($hintCount -gt 0) { Write-Host "  hints requested: $hintCount" }
}

# -- What actually goes wrong --------------------------------------------------

$failures = @($events | Where-Object { $_.event -eq 'failure' })
Write-Host ''
Write-Host 'Failures' -ForegroundColor Cyan
if ($failures.Count -eq 0) {
    Write-Host '  none recorded' -ForegroundColor DarkGray
} else {
    $failures | Group-Object failureKind | Sort-Object Count -Descending | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host 'This is ONE machine. Treat it as a signal, never as a fleet metric.' -ForegroundColor DarkGray
Write-Host ''
