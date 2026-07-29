# 0013 — Teachy agent runtime (OpenClaw for AI fluency)

**Date:** 2026-07-29
**Status:** accepted
**Affects:** teachy-app desktop Ask loop, macOS host

## The decision

Ask is a **teaching agent runtime**, not a chat turn:

| Layer | What |
|-------|------|
| SOUL | Vedant's 1:1 coach identity (always in prompt) |
| Memory | `~/.teachy/mac-agent-state.json` — path, plan, conversation, log |
| Think | Private `[THINK]` scratchpad before speech (ReAct observe/plan) |
| Plan | 3–6 step on-the-go plan when stack locks |
| Hands | `runAgentLoop` tools; Mac via System Events + Accessibility |
| Heartbeat | 4m idle nudge when mid-path (OpenClaw-style) |

Buzz/OpenClaw teach us: **shared memory + agent identity + tool loop**, not smarter single replies.

## Out of scope (next)

- Windows durable agent state in sidecar
- Full AX element tree on Mac (click uses coordinates today)
- Newsletter push-open
- Multi-agent / channels
