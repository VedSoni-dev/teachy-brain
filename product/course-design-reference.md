# Teachy course design — reference

## Decision-tree template

Fill this before writing goals.

### Trophy
`________________________________` (must be textable / showable on screen)

### HAVE buckets (customize per course)

| id | Label | They say | First move | Skips |
|----|-------|----------|------------|-------|
| nothing | Nothing yet | | | |
| ai-files | AI dump | | open/adapt files | regenerate from zero |
| design | Figma/Canva | | recreate one frame | full redesign |
| old-tool | Existing platform | | copy words that matter | full migration |
| almost | Repo/project exists | | jump near ship | foundations |
| domain | Domain only | | ship free URL first | DNS day one |

### LIVE IN (usually orthogonal)

Notes/TextEdit · VS Code · Cursor · ChatGPT/Claude browser · Figma · none

LIVE IN only changes *where* coaching happens, not the trophy.

### NEXT HELP output shape

For each (HAVE × optional LIVE) leaf:

```
pathName: …
firstMove: …
teachNext: [ordered beats]
skip: […]
trophy: (same for all)
opens: [URLs Teachy opens]
```

## Intake → memory

Teachy must `[REMEMBER:…]` / session memory:

- site/task goal
- who gets the link
- HAVE bucket
- build path (vibe vs agent)
- paid AI (if agent)

Later goals read that memory — do not re-ask the whole intake.

## Goal authoring cheatsheet

```swift
CourseLearningGoal(
    id: "stable-kebab-id",
    title: "Short verb phrase",
    goal: "Success in plain language",
    coachAsk: "Help me …",  // learner voice
    doneWhen: "What vision (or confirm) checks",
    artifactDelta: "What changed",
    remediationGoalID: "earlier-id",  // optional
    tips: ["OPEN https://… for them", …],
    teachingContext: CourseTeachingContext(
        concepts: […],
        commonMistakes: […],
        successExamples: […],
        whyItMatters: "…",
        teachBackPrompt: nil,
        skipTeachBack: true  // default true unless understanding matters
    ),
    toolPolicy: .canDoForThem,  // when open/paste required
    outcome: "One-line HUD outcome",
    advanceOnUserConfirm: true  // interview goals only
)
```

### toolPolicy guide

| Policy | Use when |
|--------|----------|
| `pointOnly` | Pure practice; never drive |
| `preferPointing` | Default coaching |
| `helpWhenStuck` | OK to act after friction |
| `canDoForThem` | Must open URLs, paste prompts, deploy chrome |

### advanceOnUserConfirm

Use when success is **spoken context**, not pixels:

- intake / path choice
- "prompt is written" with nothing on screen yet

Do **not** use to skip a required open-tool beat. If the next action is open ChatGPT, that open belongs in the same goal as the interview, or confirm must force-open (see LessonPlayer `write-the-prompt` handler).

## Happy-path skeleton (AI-fluency style)

0. **Intake** — goal, HAVE, build tool (+ paid route) · `advanceOnUserConfirm`
1. **Plan in AI tool** — interview → write prompt → open+paste → lock plan · `canDoForThem`
2. **Optional mock** — image/design (budget free gens) · `canDoForThem`
3. **Build** — open routed tool, paste plan+mocks · `canDoForThem`
4. **Ship** — host URL live · `canDoForThem`

Customize tools/hosts per course; keep the shape.

## Files to touch (Teachy repo)

| File | Role |
|------|------|
| `docs/design/YYYY-MM-DD-*.md` | Lock design |
| `leanring-buddy/ClickyCourse.swift` | Bundled catalog + coach flagship rules |
| `courses/<id>.json` | Open curriculum |
| `academy/registry.json` | Store card |
| `LessonPlayer.swift` | Only if new advance/confirm edge cases |
| Canvas (optional) | Founder-facing decision tree |

## Coach system-prompt addendum

For flagship courses, inject course-specific rules in `courseCoachSystemPrompt` (see Make a Website `flagshipWebsiteCourseSection`):

- one question at a time
- open+paste in the same turn when prompt is ready
- remember intake routing
- host/tool names (no wrong stack)

## Verify before ship

- [ ] Typed "next step" advances (not answered as chat)
- [ ] Interview goals don't vision-loop
- [ ] Open-tool goals actually open on first ready beat
- [ ] Soft-pass doesn't skip required opens
- [ ] Trophy `doneWhen` matches a real URL/artifact on screen
- [ ] JSON ↔ Swift goal ids match
