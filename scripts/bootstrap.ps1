<#
.SYNOPSIS
  Sets up the whole Teachy workspace on a fresh Windows machine.

.DESCRIPTION
  Creates a teachy/ folder holding all three repos, installs dependencies,
  builds the C# sidecar, runs the full test suite, and builds the company
  knowledge graph.

  Checks every prerequisite up front and reports all of them at once, rather
  than dying on the first missing tool and making you run it five times.

.PARAMETER Root
  Where to create the workspace. Defaults to a 'teachy' folder beside wherever
  you ran this from.

.PARAMETER SkipVerify
  Skip the build-and-test pass. Faster, but you won't know the checkout works.

.EXAMPLE
  pwsh teachy-brain/scripts/bootstrap.ps1
  pwsh teachy-brain/scripts/bootstrap.ps1 -Root D:\work\teachy
#>

[CmdletBinding()]
param(
    [string]$Root,
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

$GitHubOwner = 'VedSoni-dev'
$RepoNames = @('teachy-app', 'teachy-web', 'teachy-brain')

function Write-Step($message) { Write-Host "`n>> $message" -ForegroundColor Cyan }
function Write-Good($message) { Write-Host "   $message" -ForegroundColor Green }
function Write-Warn($message) { Write-Host "   $message" -ForegroundColor Yellow }

# ── Prerequisites ─────────────────────────────────────────────────────────────
# All checked before anything is created, so a missing tool costs one run, not
# one run per tool.

Write-Step 'Checking prerequisites'

$requirements = @(
    @{ Command = 'git';      Needed = 'required'; Install = 'https://git-scm.com/download/win' }
    @{ Command = 'gh';       Needed = 'required'; Install = 'winget install GitHub.cli   (then: gh auth login)' }
    @{ Command = 'node';     Needed = 'required'; Install = 'winget install OpenJS.NodeJS.LTS' }
    @{ Command = 'dotnet';   Needed = 'required'; Install = 'winget install Microsoft.DotNet.SDK.8' }
    @{ Command = 'graphify'; Needed = 'optional'; Install = 'pip install graphify' }
)

$missingRequired = @()
foreach ($requirement in $requirements) {
    $found = Get-Command $requirement.Command -ErrorAction SilentlyContinue
    if ($found) {
        Write-Good "$($requirement.Command) ok"
    } elseif ($requirement.Needed -eq 'required') {
        Write-Host "   $($requirement.Command) MISSING - $($requirement.Install)" -ForegroundColor Red
        $missingRequired += $requirement.Command
    } else {
        Write-Warn "$($requirement.Command) missing (optional) - $($requirement.Install)"
    }
}

if ($missingRequired.Count -gt 0) {
    throw "Install these first, then re-run: $($missingRequired -join ', ')"
}

# The repos are private, so a clone fails without auth. Say so now rather than
# letting git prompt for credentials three times.
$ghAuthOutput = (gh auth status 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
}
Write-Good 'gh authenticated'

# ── Workspace ─────────────────────────────────────────────────────────────────

if (-not $Root) {
    $Root = Join-Path (Get-Location).Path 'teachy'
}
New-Item -ItemType Directory -Force $Root | Out-Null
$Root = (Resolve-Path $Root).Path

Write-Step "Workspace: $Root"

foreach ($repoName in $RepoNames) {
    $repoPath = Join-Path $Root $repoName
    if (Test-Path (Join-Path $repoPath '.git')) {
        Write-Good "$repoName already cloned - pulling"
        git -C $repoPath pull --ff-only
    } else {
        Write-Step "Cloning $repoName"
        gh repo clone "$GitHubOwner/$repoName" $repoPath
    }
}

# ── App dependencies ──────────────────────────────────────────────────────────

$desktopPath = Join-Path (Join-Path $Root 'teachy-app') 'desktop'

Write-Step 'Installing app dependencies'
Push-Location $desktopPath
try {
    npm install
    Write-Good 'npm install done'

    if (-not $SkipVerify) {
        Write-Step 'Building and testing (sidecar + typecheck + tests + renderer)'
        npm run verify
        if ($LASTEXITCODE -ne 0) {
            throw 'npm run verify failed - the checkout is not healthy.'
        }
        Write-Good 'verify passed'
    } else {
        Write-Warn 'skipped verify (-SkipVerify)'
    }
} finally {
    Pop-Location
}

# ── Knowledge graph ───────────────────────────────────────────────────────────

if (Get-Command graphify -ErrorAction SilentlyContinue) {
    Write-Step 'Building the company knowledge graph'
    & (Join-Path (Join-Path (Join-Path $Root 'teachy-brain') 'scripts') 'rebuild-graph.ps1')
} else {
    Write-Warn 'graphify not installed - skipping the knowledge graph.'
    Write-Warn 'Install it with: pip install graphify'
    Write-Warn 'Then run: pwsh teachy-brain/scripts/rebuild-graph.ps1'
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host 'Teachy workspace ready.' -ForegroundColor Green
Write-Host ''
Write-Host "  $Root"
Write-Host '    teachy-app     macOS + Windows apps, courses, worker'
Write-Host '    teachy-web     the Academy site'
Write-Host '    teachy-brain   decisions, architecture, incidents'
Write-Host '    graph          the cross-repo knowledge graph'
Write-Host ''
Write-Host 'Run the app:      cd teachy-app\desktop; npm start'
Write-Host 'Test everything:  cd teachy-app\desktop; npm run verify'
Write-Host 'Ask the graph:    graphify explain "MicrophoneRecorder" --graph graph\teachy-graph.json'
Write-Host 'Read first:       teachy-brain\QUERYING.md'
