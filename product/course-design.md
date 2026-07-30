---
name: teachy-course-design
description: >-
  Design and ship Teachy Courses the Make-a-Website way — intake forks, active
  prompting, decision trees, open-links-for-them, tool routing, and durable
  doneWhen goals. Use when creating a new Teachy course, flagship path, learning
  track, course JSON, bundled ClickyCourse catalog entry, or when the user says
  "make a course", "new path", "replicate Make a Website", "course design", or
  "decision tree for a course".
---

# Teachy Course Design

Ship **one legendary path** at a time. Not a catalog of weak tutorials.

**Reference course:** Make a Website (`docs/design/2026-07-24-make-a-website.md`, `courses/build-a-website.json`, bundled catalog in teachy-app `packages/core/src/data/courseCatalog.ts`).

**Deeper templates:** [reference.md](reference.md) · **Worked example:** [examples.md](examples.md)

## Hard rules

1. **Design before code.** Decision tree + design doc first. No goal JSON until the tree feels right.
2. **Shared trophy.** Every fork ends at the same real outcome (a URL, a shipped artifact, a verified skill on screen).
3. **Teachy is the active prompter.** Normies type vague asks. Teachy interviews → writes the perfect prompt with them → opens the tool. The learner pastes and sends it — their hands, per [decision 0014](../decisions/0014-teachy-shows-never-acts.md). They learn prompting by *feeling* a good prompt work.
4. **Doing > navigating.** Teachy opens ChatGPT / Replit / Vercel / docs. Learner decides and reacts — never hunts tabs.
5. **Multiple on-ramps, one path.** Fork on what they already have + what they live in + what to help next — not separate courses per persona.
6. **Stable goal IDs** once shipped. Progress keys off ids.

## Workflow (copy this checklist)

```
Course design progress:
- [ ] 1. Name the trophy (one sentence a friend would text)
- [ ] 2. Situations table (what they have / say / actually need)
- [ ] 3. Intake questions (one at a time — office-hours energy)
- [ ] 4. Decision tree: HAVE → LIVE IN → NEXT HELP → trophy
- [ ] 5. Tool routing (if agents/vibecoding involved)
- [ ] 6. Design doc in docs/design/YYYY-MM-DD-<slug>.md
- [ ] 7. Implement goals (core catalog + courses/*.json)
- [ ] 8. Conversational vs vision goals (advanceOnUserConfirm)
- [ ] 9. Dogfood Phase 0–1 cold before polishing later goals
```

### 1. Trophy

One concrete finish line visible on their Mac:

- Bad: "learn HTML"
- Good: "a live Vercel URL they can text someone"

### 2. Situations (HAVE)

Build a table before goals:

| Situation | They say | First move | Skip |
|-----------|----------|------------|------|
| Nothing | "never made one" | … | … |
| AI dump | "ChatGPT wrote files" | … | don't regenerate |
| Almost done | "repo exists" | jump to ship | skip foundations |

### 3. Intake questions

Ask **one at a time**. Mirror office hours:

1. What's your goal with this? (job / school / hustle / friends / learn / fun)
2. Who do you text when it's done?
3. What do you already have?
4. What do you live in? (Notes / VS Code / Cursor / ChatGPT / Figma / none)
5. How do you want to build? (vibe tool vs coding agent) — then paid-AI routing if agent

### 4. Decision tree

Axes, in order:

1. **HAVE** — starting material  
2. **LIVE IN** — where they already work (only changes *where* you coach)  
3. **NEXT HELP** — first move + teach order + skips  

Optional: interactive canvas under `~/.cursor/projects/.../canvases/` so the founder can click forks.

### 5. Tool routing (agents)

| Already pay? | Route |
|--------------|--------|
| Cursor | Cursor |
| Claude | Claude Code |
| ChatGPT | Stay OpenAI / Codex |
| Nothing | Best free beginner tier (e.g. Codex) |
| Willing to pay | One clear paid rec (e.g. Claude Code) |
| Vibe tool | Replit (or similar) — skip paid quiz |

### 6. Design doc

Write `docs/design/YYYY-MM-DD-<slug>.md` with: Problem, Premises, Approaches (2–3), Recommended happy path, Agent/tool routing, Authoring notes, One real-world assignment before implementing.

### 7. Implement goals

Happy path as ordered goals. Encode forks in **coach instructions + memory**, not a maze of goal graphs.

For each goal set:

| Field | Rule |
|-------|------|
| `coachAsk` | What the learner would ask Teachy |
| `doneWhen` | Visible on screen OR `advanceOnUserConfirm: true` |
| `toolPolicy` | Open-only: Teachy may open the tool/URL. It never types or pastes in the learner's work ([0014](../decisions/0014-teachy-shows-never-acts.md)) |
| `tips` | Include "OPEN https://… for them" |
| `teachingContext` | concepts, mistakes, successExamples, skipTeachBack |

**Ship in both places:**

- Bundled: `courseCatalog.ts` in teachy-app `packages/core/src/data/`
- Open curriculum: `courses/<id>.json`
- Registry card: `academy/registry.json` if featured

### 8. Conversational vs vision (don't get stuck)

| Goal type | Pattern |
|-----------|---------|
| Interview / path choice | `advanceOnUserConfirm: true`, skipTeachBack, no vision gate |
| Interview → open tool → learner pastes | **One goal.** After enough answers, open the tool in the **same turn**, prompt ready for them to paste. Never wait for "next step" to open a link. |
| Screen proof (preview, deploy) | Real `doneWhen`; vision verify OK |

**Known bug class:** typed "next step" must route like voice (`LessonPlayer.handleTextQuestion`). Soft-pass must not skip a required open-tool beat.

### 9. Dogfood

Run Phase 0–1 out loud on a real human (or yourself cold) before polishing later goals. Note where the interview drags or feels thin.

## Product voice (Teachy)

- Warm, one beat at a time, point at real UI
- `[INFO]` + `[TODO]` when coaching
- Open URLs with tools; hand them the prompt to paste; don't lecture "how to prompt"
- Remember intake (build tool, paid AI, what they have) for the whole session

## Anti-patterns

- Linear tutorial with no HAVE forks  
- Starting on theory before a plan in a real AI tool  
- Making them find chatgpt.com / vercel.com themselves  
- Separate courses per persona instead of intake forks  
- Vision-verifying "we wrote a prompt" (nothing on screen)  
- Splitting "write prompt" and "open ChatGPT" into two goals with a next-step gate between them  
- Bloated catalog before one path is legendary  
