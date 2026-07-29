# 0015 — Teachy can borrow a Claude Pro / ChatGPT subscription over ACP

**Date:** 2026-07-29
**Status:** accepted
**Affects:** teachy-app AI backend (Swift **and** Electron), onboarding key gate, B2C cost story

## The question

Teachy's free promise has a hole in it: "free to use, bring your own key" still
asks a learner to fund OpenRouter credits before the tutor says anything. A lot
of the people we want already pay for Claude Pro or ChatGPT Plus. Can Teachy use
the subscription they already have instead of asking for a second wallet?

## The decision

**Yes, via the Agent Client Protocol.** Both vendors ship a CLI that holds a
logged-in subscription session, and both have an ACP adapter that exposes it over
stdio JSON-RPC. Teachy spawns the adapter and prompts through it:

| Runtime | Adapter (npm) | Session held by |
|---------|---------------|-----------------|
| Claude  | `@agentclientprotocol/claude-agent-acp` | `claude` CLI |
| Codex   | `@zed-industries/codex-acp` | `codex` CLI |

…and **any third agent that speaks ACP**, including a company's own. See
"Bring your own agent" below.

**It ships on both platforms.** The Electron/React desktop is the cross-platform
implementation per [0011](0011-mac-ships-electron-react.md), so Windows and Mac
get this from one codebase; the Swift app has its own copy because that is what
Sparkle-updated B2C installs run today.

| Surface | Seam | Reaches |
|---------|------|---------|
| `desktop/` (Windows + Mac) | `postOpenRouterChat` in `src/state/openRouterClient.ts` | companion, courseVerifier, agentPlan, agentLoop |
| `leanring-buddy/` (Mac, Sparkle) | `ClaudeAPI` | all 4 call shapes, 14 call sites |

Both seams already branched proxy vs. direct-key, so ACP is a third branch
checked first and **no caller changed**. On the Electron side that fell out
especially cleanly: `postOpenRouterChat` returns a `Response`, so the ACP path
synthesises an OpenAI-shaped `Response` — real incremental SSE frames for
streaming callers, a `chat.completion` JSON body for the rest. Nothing
downstream can tell which backend answered.

**Teachy never sees a credential.** The session stays in the vendor CLI's own
store. Teachy persists only "which runtime" and "on/off".

## Bring your own agent — including an internal one

The runtime list is not hardcoded. A JSON file in
`ACPHarnesses/` (`%APPDATA%\Teachy\` on Windows,
`~/Library/Application Support/Teachy/` on Mac) adds a runtime that appears in
the picker beside Claude and Codex:

```json
{ "id": "acme-agent", "label": "Acme Internal Agent",
  "command": "acme-agent-acp", "args": ["acp"],
  "env": { "ACME_ENDPOINT": "https://ai.acme.internal" } }
```

`args` and `env` are the load-bearing fields, and the reason the built-in shape
alone wasn't enough: an internal tool is almost never a purpose-built binary. It
is `company-cli acp`, or `node /opt/agent/index.js --acp`, usually pointed at a
private endpoint. `command` may be an absolute path.

Why this matters beyond convenience: a company that already routes model traffic
through its own CLI for policy, logging, or a private endpoint can use Teachy
without any learner data leaving that perimeter. Teachy adds no new egress — it
spawns the tool the company already trusts.

Two rules the loader enforces, both learned from how this fails:

- **A malformed harness is reported, never skipped.** These are hand-written
  files; a typo is the normal case. A silent skip is indistinguishable from
  "Teachy ignored my tool", so parse errors travel with the runtime list and
  render in the settings card.
- **A custom harness cannot claim `claude` or `codex`.** Silently shadowing a
  built-in would be miserable to debug.

With no `auth_probe` declared Teachy reports the runtime ready once the command
exists and lets the first real turn surface any auth error, rather than inventing
a check that produces a confident wrong answer.

## The turn id is minted by the caller

Non-obvious and worth writing down. The renderer generates the id it tags a turn
with and passes it *into* the main process, rather than the main process
generating one and returning it.

The obvious design doesn't work: the IPC handler's return value only arrives once
the turn has *finished*, but chunks stream throughout — so a renderer waiting to
be told its own id has to accept every chunk in the meantime. Since the coach and
a course verifier can both be mid-turn, that means one's text lands in the
other's reply. Caught by a test before it shipped, not in the wild.

## The tutor is not allowed to act

These adapters front real coding agents with file and shell tools. Enabling one
inside Teachy without constraints would hand a learner's Mac to an agent that can
edit files and run commands — squarely against
[0014](0014-teachy-shows-never-acts.md).

Four independent constraints, all on by default:

1. `initialize` advertises **no** filesystem and **no** terminal capability.
2. The session is pinned to the runtime's most restrictive mode (`default` for
   Claude, `read-only` for Codex).
3. Every `session/request_permission` is answered **reject_always**.
4. cwd is an empty scratch directory, so a file tool that runs anyway finds
   nothing.

`ACPBrainStore.allowsAgentTools` relaxes all four. It is off by default and
should stay off for anyone who isn't deliberately experimenting.

## Why these specific shapes

Verified against the live adapters rather than documentation, and three findings
drove the design:

- **`promptCapabilities.image: true` on both.** Screen coaching survives the
  transport. Had this been false the feature would only have been good for course
  generation.
- **Logged-out fails at `session/prompt`, not `initialize`**, as JSON-RPC
  `-32000 "Authentication required"`. So auth state cannot be established at
  connect time; it is mapped from the turn's error into a typed
  `authenticationRequired` that the settings card turns into a Sign In button.
- **`claude auth status` exits 0 whether or not you are signed in.** It returns
  `{"loggedIn": bool}`. Anything branching on exit code — including the reference
  implementation this was modelled on — reports every logged-out user as signed
  in. We parse the JSON.

One long-lived adapter process, one fresh session per request: process startup is
the expensive part, and Teachy's callers pass full history on every call, so a
reused stateful session would double-count the conversation.

## What it costs us

- **A GUI app has almost no PATH — and the fix differs by OS.** On macOS a
  Finder-launched `.app` inherits `/usr/bin:/bin:/usr/sbin:/sbin`, while `claude`
  installs to `~/.local/bin` and node to `/opt/homebrew/bin`; the locator runs the
  login shell with `-ilc` and a sentinel marker to recover the real PATH. Windows
  has no login shell to ask, so it uses PATH plus known install directories
  (`%APPDATA%\npm`, `%USERPROFILE%\.local\bin`). If either probe breaks, the
  feature reports "not installed" to people who have it installed.
- **npm global CLIs are `.cmd` shims on Windows**, and `spawn()` cannot execute
  those. `shell: true` would seem to fix it and then break on the spaces in
  `C:\Users\First Last\…`, so batch shims route through `cmd.exe /d /s /c` with
  `windowsVerbatimArguments`. `buildSpawnArgs` takes the platform as an argument
  so this branch is unit-tested from a Mac — otherwise the one path that only
  runs on Windows would be the one path nobody can run.
- **The background agent still can't ride ACP.** `BackgroundAgentManager` runs
  Teachy's own tool loop; an ACP agent runs *its* loop with *its* tools. Screen
  control stays on OpenRouter.
- **No token accounting.** Usage counts against the learner's subscription
  limits, and Teachy can't see how much is left.
- **Two more install steps** (vendor CLI, then adapter) before first use.
- **Two implementations of the same protocol**, which is the failure mode
  [0003](0003-windows-is-electron-plus-a-csharp-sidecar.md) names. Accepted here
  because the Swift app still ships to real users and the protocol surface is
  small and frozen (ACP v1), but a third copy would not be acceptable.

## Ported to teachy-b2b after all — Ved's call, 2026-07-29

An earlier revision of this record argued against it: an enterprise buyer does not
want employees' **personal** Claude Pro subscriptions powering a corporate tool.
That concern is real and unchanged. Ved's call was to ship it in both repos
anyway, and the custom-harness path is what makes that defensible — a company
points Teachy at its own ACP agent, so the same feature that borrows a personal
subscription in B2C borrows the **company-provisioned** one in B2B. Same
mechanism, different harness.

What that leaves open: nothing stops a B2B learner picking personal Claude in the
runtime picker. An admin-side lock ("only these runtime ids") is the missing
piece if this is ever sold into a regulated buyer.

## When to revisit

Delete the Swift copy when Sparkle installs have migrated to the Electron shell
per [0011](0011-mac-ships-electron-react.md) — until then both are live and the
Electron one is canonical.

Revisit the deny-all-tools posture only if a course genuinely needs the agent to
touch files — and read [0014](0014-teachy-shows-never-acts.md) first, because it
probably doesn't.
