#!/usr/bin/env bash
# Sets up the whole Teachy workspace on a fresh macOS or Linux machine.
#
# Creates a teachy/ folder with the public repos, installs the Electron engine,
# runs verify, and builds the knowledge graph when graphify is available.
#
# Usage:
#   ./bootstrap.sh [target-directory]

set -euo pipefail

GITHUB_OWNER="VedSoni-dev"
REPO_NAMES=(teachy-app teachy-web teachy-brain)

step() { printf '\n>> %s\n' "$1"; }
good() { printf '   %s\n' "$1"; }
warn() { printf '   %s\n' "$1" >&2; }

step "Checking prerequisites"

missing_required=()
check_tool() {
  local command_name="$1" requirement="$2" install_hint="$3"
  if command -v "$command_name" >/dev/null 2>&1; then
    good "$command_name ok"
  elif [ "$requirement" = required ]; then
    warn "$command_name MISSING - $install_hint"
    missing_required+=("$command_name")
  else
    warn "$command_name missing (optional) - $install_hint"
  fi
}

check_tool git      required "xcode-select --install, or your package manager"
check_tool gh       required "brew install gh   (then: gh auth login)"
check_tool node     required "brew install node"
check_tool dotnet   optional "brew install --cask dotnet-sdk   (Windows sidecar only)"
check_tool graphify optional "pip install graphifyy   (CLI is still graphify)"
check_tool pwsh     optional "brew install --cask powershell   (brain scripts)"

if [ ${#missing_required[@]} -gt 0 ]; then
  echo "Install these first, then re-run: ${missing_required[*]}" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi
good "gh authenticated"

WORKSPACE_ROOT="${1:-$PWD/teachy}"
mkdir -p "$WORKSPACE_ROOT"
WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" && pwd)"

step "Workspace: $WORKSPACE_ROOT"

for repo_name in "${REPO_NAMES[@]}"; do
  repo_path="$WORKSPACE_ROOT/$repo_name"
  if [ -d "$repo_path/.git" ]; then
    good "$repo_name already cloned - pulling"
    git -C "$repo_path" pull --ff-only
  else
    step "Cloning $repo_name"
    gh repo clone "$GITHUB_OWNER/$repo_name" "$repo_path"
  fi
done

# Private B2B edition — skip cleanly if the account cannot see it.
b2b_path="$WORKSPACE_ROOT/teachy-b2b"
if [ -d "$b2b_path/.git" ]; then
  good "teachy-b2b already cloned - pulling"
  git -C "$b2b_path" pull --ff-only || warn "teachy-b2b pull failed"
elif gh repo view "$GITHUB_OWNER/teachy-b2b" >/dev/null 2>&1; then
  step "Cloning private teachy-b2b"
  gh repo clone "$GITHUB_OWNER/teachy-b2b" "$b2b_path"
else
  warn "teachy-b2b not visible to this GitHub account — B2C-only workspace (ask Ved for access)"
fi

step "Installing teachy-app (engine + B2C)"
(
  cd "$WORKSPACE_ROOT/teachy-app"
  npm install
  if npm approve-scripts --help >/dev/null 2>&1; then
    npm approve-scripts electron || true
  fi
  # npm that blocks postinstall leaves Electron without a binary; verify still passes.
  if [ ! -e node_modules/electron/dist ] && [ ! -e node_modules/.bin/electron ]; then
    warn "Electron binary missing — running electron install.js"
    node node_modules/electron/install.js 2>/dev/null \
      || (cd apps/b2c && node ../../node_modules/electron/install.js) 2>/dev/null \
      || warn "Could not install Electron binary; app launch may fail until you fix it"
  fi
  npm run verify
)
good "teachy-app verify passed"

if [ -d "$b2b_path/.git" ]; then
  step "Installing teachy-b2b"
  (
    cd "$b2b_path"
    npm install
    if npm approve-scripts --help >/dev/null 2>&1; then
      npm approve-scripts electron || true
    fi
    npm run verify
  )
  good "teachy-b2b verify passed"
fi

if command -v pwsh >/dev/null 2>&1; then
  step "Installing brain self-maintenance hooks"
  pwsh -File "$WORKSPACE_ROOT/teachy-brain/scripts/install-hooks.ps1" || warn "hooks install skipped"
fi

if command -v graphify >/dev/null 2>&1; then
  step "Building the company knowledge graph"
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -File "$WORKSPACE_ROOT/teachy-brain/scripts/rebuild-graph.ps1" || warn "graph rebuild failed"
  else
    warn "pwsh missing — skip graph rebuild (install PowerShell, then: pwsh teachy-brain/scripts/rebuild-graph.ps1)"
  fi
else
  warn "graphify not installed - skipping the knowledge graph."
fi

cat <<EOF

Teachy workspace ready (Electron — no Swift / Xcode).

  $WORKSPACE_ROOT
    teachy-app     engine (packages/core) + free edition (apps/b2c)
    teachy-web     Academy site
    teachy-brain   decisions / known issues
    teachy-b2b     private workplace edition (if you have access)

Start B2C:        cd teachy-app && npm run start
Verify B2C:       cd teachy-app && npm run verify
Start B2B:        cd teachy-b2b && npm run start
Intern sheet:     teachy-app/INTERN.md
Dev layout:       teachy-app/DEVELOPMENT.md
Ask the graph:    graphify explain "openApp" --graph graph/teachy-graph.json
EOF
