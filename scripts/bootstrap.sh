#!/usr/bin/env bash
# Sets up the whole Teachy workspace on a fresh macOS or Linux machine.
#
# Creates a teachy/ folder holding all three repos and builds the knowledge
# graph. On macOS it also opens the Xcode project path for the Mac app; the
# Windows app's C# sidecar only builds on Windows, so its tests are skipped
# unless the .NET SDK happens to be present.
#
# Checks every prerequisite up front and reports all of them at once, rather
# than dying on the first missing tool and making you run it five times.
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
check_tool dotnet   optional "brew install --cask dotnet-sdk   (only needed to build the Windows sidecar)"
check_tool graphify optional "pip install graphify"

if [ ${#missing_required[@]} -gt 0 ]; then
  echo "Install these first, then re-run: ${missing_required[*]}" >&2
  exit 1
fi

# The repos are private, so a clone fails without auth. Say so now rather than
# letting git prompt for credentials three times.
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

step "Installing app dependencies"
( cd "$WORKSPACE_ROOT/teachy-app/desktop" && npm install )
good "npm install done"

if command -v dotnet >/dev/null 2>&1; then
  step "Running the test suite"
  ( cd "$WORKSPACE_ROOT/teachy-app/desktop" && npm run verify )
  good "verify passed"
else
  warn "no .NET SDK - skipping the Windows sidecar build and its tests."
  warn "The renderer tests still run with: cd teachy-app/desktop && npm test"
fi

if command -v graphify >/dev/null 2>&1; then
  step "Building the company knowledge graph"
  graph_paths=()
  for repo_name in "${REPO_NAMES[@]}"; do
    graphify update "$WORKSPACE_ROOT/$repo_name" >/dev/null
    graph_paths+=("$WORKSPACE_ROOT/$repo_name/graphify-out/graph.json")
  done
  mkdir -p "$WORKSPACE_ROOT/graph"
  graphify merge-graphs "${graph_paths[@]}" --out "$WORKSPACE_ROOT/graph/teachy-graph.json"
else
  warn "graphify not installed - skipping the knowledge graph."
  warn "Install it with: pip install graphify"
fi

cat <<EOF

Teachy workspace ready.

  $WORKSPACE_ROOT
    teachy-app     macOS + Windows apps, courses, worker
    teachy-web     the Academy site
    teachy-brain   decisions, architecture, incidents
    graph          the cross-repo knowledge graph

Mac app:          open $WORKSPACE_ROOT/teachy-app/leanring-buddy.xcodeproj
Windows app:      cd teachy-app/desktop && npm start
Ask the graph:    graphify explain "MicrophoneRecorder" --graph graph/teachy-graph.json
Read first:       teachy-brain/QUERYING.md
EOF
