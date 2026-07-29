<#
.SYNOPSIS
  Sets up the whole Teachy workspace on a fresh Windows machine.

.DESCRIPTION
  Creates a teachy/ folder with the public repos, installs the Electron engine,
  builds/tests (including the C# sidecar when present), and builds the company
  knowledge graph when graphify is available.

.PARAMETER Root
  Where to create the workspace. Defaults to a 'teachy' folder beside wherever
  you ran this from.

.PARAMETER SkipVerify
  Skip the build-and-test pass.

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

Write-Step 'Checking prerequisites'

$requirements = @(
    @{ Command = 'git';      Needed = 'required'; Install = 'https://git-scm.com/download/win' }
    @{ Command = 'gh';       Needed = 'required'; Install = 'winget install GitHub.cli   (then: gh auth login)' }
    @{ Command = 'node';     Needed = 'required'; Install = 'winget install OpenJS.NodeJS.LTS' }
    @{ Command = 'dotnet';   Needed = 'required'; Install = 'winget install Microsoft.DotNet.SDK.8' }
    @{ Command = 'graphify'; Needed = 'optional'; Install = 'pip install graphifyy' }
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

$ghAuthOutput = (gh auth status 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
}
Write-Good 'gh authenticated'

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

$b2bPath = Join-Path $Root 'teachy-b2b'
if (Test-Path (Join-Path $b2bPath '.git')) {
    Write-Good 'teachy-b2b already cloned - pulling'
    git -C $b2bPath pull --ff-only
} else {
    gh repo view "$GitHubOwner/teachy-b2b" 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Step 'Cloning private teachy-b2b'
        gh repo clone "$GitHubOwner/teachy-b2b" $b2bPath
    } else {
        Write-Warn 'teachy-b2b not visible — B2C-only workspace (ask Ved for access)'
    }
}

Write-Step 'Installing brain self-maintenance hooks'
& (Join-Path (Join-Path (Join-Path $Root 'teachy-brain') 'scripts') 'install-hooks.ps1')

function Install-TeachyNpmWorkspace([string]$WorkspacePath, [string]$Label) {
    Write-Step "Installing $Label"
    Push-Location $WorkspacePath
    try {
        npm install
        npm approve-scripts electron 2>$null
        if (-not (Test-Path 'node_modules\electron\dist') -and -not (Test-Path 'node_modules\.bin\electron.cmd')) {
            Write-Warn 'Electron binary missing — running electron install.js'
            if (Test-Path 'node_modules\electron\install.js') {
                node node_modules\electron\install.js
            }
        }
        if (-not $SkipVerify) {
            Write-Step "Verifying $Label"
            npm run verify
            if ($LASTEXITCODE -ne 0) {
                throw "npm run verify failed in $Label"
            }
            Write-Good "$Label verify passed"
        } else {
            Write-Warn "skipped verify for $Label (-SkipVerify)"
        }
    } finally {
        Pop-Location
    }
}

Install-TeachyNpmWorkspace (Join-Path $Root 'teachy-app') 'teachy-app (engine + B2C)'

if (Test-Path (Join-Path $b2bPath '.git')) {
    Install-TeachyNpmWorkspace $b2bPath 'teachy-b2b'
}

if (Get-Command graphify -ErrorAction SilentlyContinue) {
    Write-Step 'Building the company knowledge graph'
    & (Join-Path (Join-Path (Join-Path $Root 'teachy-brain') 'scripts') 'rebuild-graph.ps1')
} else {
    Write-Warn 'graphify not installed - skipping the knowledge graph.'
    Write-Warn 'Install it with: pip install graphifyy'
}

Write-Host ''
Write-Host 'Teachy workspace ready (Electron — no Swift / Xcode).' -ForegroundColor Green
Write-Host ''
Write-Host "  $Root"
Write-Host '    teachy-app     engine (packages/core) + free edition (apps/b2c)'
Write-Host '    teachy-web     Academy site'
Write-Host '    teachy-brain   decisions / known issues'
Write-Host '    teachy-b2b     private workplace edition (if you have access)'
Write-Host ''
Write-Host 'Start B2C:        cd teachy-app; npm run start'
Write-Host 'Verify B2C:       cd teachy-app; npm run verify'
Write-Host 'Start B2B:        cd teachy-b2b; npm run start'
Write-Host 'Intern sheet:     teachy-app\INTERN.md'
Write-Host 'Dev layout:       teachy-app\DEVELOPMENT.md'
Write-Host 'Ask the graph:    graphify explain "openApp" --graph graph\teachy-graph.json'
