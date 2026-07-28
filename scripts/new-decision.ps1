<#
.SYNOPSIS
  Scaffolds a new decision record with the right shape and the next number.

.DESCRIPTION
  Write-back only happens if it is cheaper than not writing back. Asking anyone -
  human or agent - to remember the numbering scheme, the section order, and that
  the cost section is mandatory is asking them to skip it. This makes it one
  command.

  The template is opinionated on purpose. "What it costs us" is pre-filled with a
  prompt rather than left blank, because a record with no downside listed reads
  as marketing and quietly teaches the next reader that these are not worth
  reading.

.PARAMETER Title
  The decision, as a short sentence. Becomes the heading and the filename slug.

.EXAMPLE
  pwsh teachy-brain/scripts/new-decision.ps1 -Title "Fetch the model list at runtime"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Title
)

$ErrorActionPreference = 'Stop'

$brainRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$decisionsDirectory = Join-Path $brainRoot 'decisions'
New-Item -ItemType Directory -Force $decisionsDirectory | Out-Null

# Next number, from what already exists. Gaps are fine; collisions are not.
$highestNumber = 0
Get-ChildItem $decisionsDirectory -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Name -match '^(\d{4})-') {
        $number = [int]$Matches[1]
        if ($number -gt $highestNumber) { $highestNumber = $number }
    }
}
$nextNumber = '{0:D4}' -f ($highestNumber + 1)

$slug = ($Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
$fileName = "$nextNumber-$slug.md"
$filePath = Join-Path $decisionsDirectory $fileName

if (Test-Path $filePath) { throw "Already exists: $filePath" }

$today = (Get-Date).ToString('yyyy-MM-dd')

$template = @"
# $nextNumber - $Title

**Date:** $today
**Status:** accepted
**Affects:** <which repos, which people, what breaks if this is wrong>

## The question

<What was actually being decided, and what made it a real choice rather than an
obvious one. If there was no genuine alternative, this is not a decision record.>

## Decision

<The call, stated flatly. One or two sentences.>

## Why

<The reasoning that would survive someone disagreeing with it. Not a summary of
the decision - the argument for it.>

## What it costs us

<MANDATORY. Every decision buys something and pays for it somewhere. Name the
price honestly: what got slower, harder, more fragile, or more expensive. A
record with no downside listed reads as marketing, and the next person can tell,
so they stop trusting all of them.>

## Revisit when

<The observation that should make someone reopen this. A threshold, a signal, a
date - something checkable, not "if it becomes a problem".>

## See also

<Links to related records, the code this constrains, or the incident that caused it.>
"@

Set-Content -Path $filePath -Value $template -Encoding utf8

Write-Host "Created $filePath" -ForegroundColor Green
Write-Host ''
Write-Host 'Then:' -ForegroundColor Cyan
Write-Host '  1. Fill it in - especially "What it costs us".'
Write-Host '  2. Add it to the table in README.md.'
Write-Host '  3. Commit. The graph rebuilds itself.'
