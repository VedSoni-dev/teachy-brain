# Teachy — Product & Technical Guide

This document explains **what Teachy is**, **why it exists**, **how it works under the hood**, and **how courses are designed, authored, and taught**. It is the long-form companion to `README.md` (quick start) and `AGENTS.md` (engineering map).

---

## 1. What Teachy is

**Teachy** is a free, open-source **macOS teaching companion**: a 1:1 tutor that lives in the menu bar, sees the learner’s real screen, points at real UI, and coaches until something actually works.

It is **not**:

- Another video player or course marketplace in a browser
- A chatbot that only talks about coding in the abstract
- A scripted macro that clicks hardcoded button coordinates

It **is**:

- Practice on the **real computer** (apps, browser, Terminal, Finder)
- **Act-first** learning: the learner does the work; Teachy coaches and checks
- **Goal-based courses** that survive UI redesigns (natural-language outcomes, not pixel layouts)
- An open platform: MIT-licensed app + JSON curriculum anyone can ship

**Lineage:** Born from Farza’s [Clicky](https://www.heyclicky.com/) experiments. This line is **Teachy** — courses-first, teach-by-doing, open curriculum. The local repo folder may still be named `clicky` / `leanring-buddy` for historical reasons; the product name is **Teachy**.

**North star:** Become the default way people learn to do real work on a computer — free, 1:1, act-first. Think *next-generation Khan Academy*, but the classroom is the learner’s Mac.

### Business: two products, one engine

| Product | Who | Offer |
|---------|-----|--------|
| **Teachy** | Individuals | Free 1:1 tutor that can **teach anything** on the real Mac screen (AI tools, building, shipping, workflows). |
| **Teachy Enterprise** | Companies | **Bespoke AI** systems plus the Teachy teaching layer for **employee AI fluency** — custom paths on *their* tools, SOPs, and stack. Verified skills, not slide decks. |

**Market wedge:** AI fluency is the new literacy. Orgs buy seats for ChatGPT/Copilot/Claude; almost none teach people to use them well on real work. Teachy is practice + verification. Enterprise is that loop tailored to the company, plus bespoke AI.

Website: `academy/index.html` · Enterprise: `academy/enterprise.html` · Sales brief: `docs/ENTERPRISE.md` · contact: `enterprise@teachy.app` (update when you have a real domain/inbox).

---

## 2. Goals

### Product goals

| Goal | Meaning |
|------|---------|
| **Learn by doing** | Watching tutorials is the old way. Teachy points, waits, and verifies on the learner’s screen. |
| **One legendary path at a time** | Ship a small number of excellent tracks (on-ramp → flagship → related paths), not a bloated catalog of weak content. |
| **Free forever positioning** | Core teaching stays free and open-source so distribution isn’t gated by paywalls. |
| **Durable outcomes** | Courses encode *what success looks like*, not *which button was blue last week*. |
| **Trust** | Screen data and keys handled carefully; AI traffic goes through a proxy; sensitive keys never ship in the app binary. |
| **Mac-first** | Master the teaching loop on macOS before Windows / browser companions. |

### Learning goals (pedagogy)

1. **Point → act → check** on the real UI  
2. Optional short **teacher clips** (context), then hands-on coaching  
3. **Vision verification** that the outcome is actually on screen  
4. Soft **teach-back** (“in your words…”) so understanding sticks  
5. **Memory** of what the learner knows / struggles with across a course  
6. Longer term: skill graphs, spaced repetition, portfolios of real artifacts  

### Platform goals

- **Open curriculum** — courses as JSON + optional video URLs  
- **Teachy Academy** — free static site for discovery, demos, and install URLs  
- **Community distribution** — free DMGs via GitHub Releases (Sparkle updates)  

---

## 3. Potential

Teachy’s wedge is hard to copy with “another LMS”:

| Advantage | Why it matters |
|-----------|----------------|
| **Real-screen coaching** | Help is specific to *this* Mac, *this* app version, *this* messy desktop. |
| **Verification loop** | Completion isn’t “watched 80% of video” — it’s “vision says the goal is done.” |
| **Cursor as teacher** | Pointing is visceral; people feel tutored, not lectured. |
| **Open curriculum** | Teachers and communities can publish paths without waiting for a closed marketplace. |
| **Engine headroom** | `TeachyEngine` (learner model, skill graph, teach-back depth, spaced repetition, portfolio) can become a real adaptive tutor — not just a scripted checklist. |

### Where it can grow

1. **Consumer Teachy** — anyone learning AI fluency, building, shipping, tools (free forever wedge)  
2. **Teachy Enterprise (revenue)** — bespoke AI + custom employee teaching paths; pilots → company-wide AI fluency rollouts  
3. **Curriculum network** — open paths + private enterprise curriculum  
4. **Outcomes as social proof** — shareable “I shipped X” / fluency cards, finish-rate analytics  
5. **Cross-device** — Windows / browser teaching once Mac loop is legendary  
6. **Monetization without killing free forever** — Enterprise + optional hosted proxy / team seats; core personal app and open paths stay free  

The strategic bet: **the product is the teaching loop**, not the video library. Content is fuel; the engine is the moat. Enterprise sells the engine + bespoke AI to companies that need AI-fluent teams.

---

## 4. How it works (system overview)

### High-level architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Learner (macOS 14.2+)                                      │
│  Menu bar icon → notch panel → Courses / Home               │
│  ctrl+option push-to-talk · blue cursor overlay · lesson HUD│
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Teachy.app (Swift / SwiftUI + AppKit)                      │
│                                                             │
│  CompanionManager     — central state machine               │
│  LessonPlayer         — course loop (coach → turn → verify) │
│  CoursesManager       — catalog, sessions, progress, memory │
│  CourseVerifier       — vision pass / partial / off-track   │
│  TeachyEngine/*       — learner model, skills, teach-back   │
│  Mac tools            — UI click, browser, bash, AppleScript│
│  Overlay + ScreenCaptureKit + optional teacher video player │
└────────────────────────────┬────────────────────────────────┘
                             │ all AI / STT token traffic
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Teachy proxy (worker/)                                     │
│  Local: localhost:8787 · Prod: Cloudflare Worker            │
│  OpenRouter (chat + agent) · AssemblyAI tokens · optional   │
│  Anthropic / ElevenLabs                                     │
│  API keys live only on the proxy — never in the app binary  │
└─────────────────────────────────────────────────────────────┘
```

### App shape

- **Menu-bar only** (`LSUIElement = true`) — no dock icon, no traditional main window  
- **Notch-style panel** (boring.notch–inspired) — hover/open for Learn + settings  
- **Full-screen transparent overlay** — blue companion cursor, speech, pointing animations  
- **Course lesson HUD** — current goal, coach line, Hint / I did it (Teachy shows; never does it for them — decision 0014)  

### Outside a course

Push-to-talk answers quick on-screen questions: screenshot → vision model → spoken reply + optional pointing. Free-form background “Agents” UI is demoted (hidden); Mac tools still power in-lesson automation.

### Inside a course

All voice and HUD actions route through **`LessonPlayer`**. The player drives an ordered list of **goals** until the course finishes or the learner cancels.

### Permissions (why they exist)

| Permission | Use |
|------------|-----|
| **Screen Recording** | Screenshots for coaching and verification |
| **Accessibility** | Cursor pointing and optional UI actions |
| **Microphone** | Push-to-talk voice |

### Data on disk

| Path | Contents |
|------|----------|
| `~/.teachy/courses/` | Installed course JSON (legacy `~/.clicky/courses/` still works) |
| `~/.teachy/connectors/` | OpenAPI / HTTP connector manifests for agent tools |
| Engine state under `~/.teachy/` | Learner model / engine persistence (when enabled) |

### Distribution

- Free **DMGs** on GitHub Releases (community builds: ad-hoc signed; right-click → Open once for Gatekeeper)  
- **Sparkle** checks `appcast.xml` and verifies EdDSA signatures  
- Website: static **Academy** site on GitHub Pages (`academy/` → `gh-pages`)  

---

## 5. How courses are taught (technical)

This is the core product loop. Courses are **not** slide decks. They are **goal graphs** executed by a runtime.

### 5.1 Mental model

```
Course
  └── goals[]   (ordered durable outcomes)
        each goal:
          optional teacher video
          → auto coachAsk (vision + pointing)
          → learner's turn (do the work)
          → verify doneWhen (vision)
          → optional teach-back
          → next goal (or remediate)
```

Nothing in a goal should name a specific button label, grid cell, or pixel layout. Those change when GitHub or VS Code redesigns. Teachy re-derives *where to point* from the live screenshot every turn.

### 5.2 Runtime components

| Component | File (approx.) | Job |
|-----------|----------------|-----|
| **Course model** | `ClickyCourse.swift` | Codable course + goals + tracks + tool policy |
| **Catalog / session** | `CoursesManager.swift` | Bundled + installed courses, progress, memory |
| **Player** | `LessonPlayer.swift` | Async loop: placement → goals → advance/complete |
| **Verifier** | `CourseVerifier.swift` | Structured vision: pass / partial / offTrack |
| **HUD** | `CourseLessonHUDWindow.swift` | Coach line, chips, Hint / Do it / I did it |
| **Grounding** | `CourseUIGrounder.swift` | Soft open of `startURL`; capture cursor screen |
| **Teaching support** | `TeachyTeachingSupport.swift` | Prompts, memory tags, video notes injection |
| **Engine** | `TeachyEngine/*` | Deeper pedagogy (skills, SR, portfolio, teach-back depth) |

### 5.3 Session lifecycle

1. **Learner starts a course** from the Learn tab (bundled catalog or installed JSON).  
2. **`CoursesManager`** opens a `ClickyCourseSession` (course + current goal index + conversation memory).  
3. **`LessonPlayer.start()`** runs `runCourseLoop()` on the main actor.  
4. Optional **placement check** on first goal: short knowledge vibe check (brand new / some experience / already building).  
5. For each goal: **`runCurrentGoal`** (see below).  
6. On success: advance index, celebrate / continue, or finish the course.  
7. Progress persists so **Continue learning** can resume mid-path.

### 5.4 Per-goal pipeline (what actually runs)

Order of operations for one goal:

```
1. Soft start (once per course)
   - If course.startURL is set → open it (homepage only; not a layout contract)

2. Optional course intro video (once per session)
   - teacherVideoURL / introVideoURL beside the cursor
   - Learner can Skip (HUD or say “skip”)

3. Optional goal part video
   - Per-goal teacherVideoURL
   - teacherVideoNotes may be injected into coaching context after playback

4. Coaching turn(s)
   - LessonPlayer feeds goal.coachAsk (plus teachingContext, tips, memory)
   - Companion vision path: screenshot (+ optional chalk outline) → model
   - Model may emit [POINT:…] / [DRAW:…] / [INFO] / [TODO] / [MEMORY:…]
   - Overlay animates cursor; TTS speaks coach lines
   - toolPolicy controls whether Mac tools may click/type for the learner

5. Your turn
   - Phase becomes “learner acts”
   - HUD: Hint · Do it for me · I did it (and voice equivalents)
   - Empty hotkey / “I did it” / natural advance language resumes the loop

6. Verification
   - CourseVerifier captures screen and checks natural-language doneWhen
   - Structured result: pass | partial | offTrack (+ what’s good / missing)
   - Failures can re-coach, hint, or jump to remediationGoalID

7. Teach-back (soft, unless skipTeachBack)
   - “In your words…” / teachingContext.teachBackPrompt
   - Answer updates learner memory (knows / confusedBy, preferences)
   - TeachyEngine can score richer teach-back depths when wired in

8. Advance to next goal or complete course
```

### 5.5 Coach asks and the vision path

Goals do **not** hardcode steps like “click the green button at (x,y).” Instead:

- **`coachAsk`** is phrased like something a human would say to a tutor  
  e.g. *“Help me create my first HTML file… walk me through it.”*  
- That string is injected into the **same companion vision pipeline** used outside courses.  
- The model sees labeled screenshots (with an internal coordinate grid).  
- Weaker models point with tags such as **`[POINT:M6:label]`** (grid cells A–T × 1–12).  
- Stronger paths can use Mac tools (`ui_action`, browser, Terminal) when **toolPolicy** allows and the learner is stuck or asks **“do it for me.”**

So a course is an **auto-prompter + verifier + memory**, not a separate teaching engine that redraws the whole UI.

### 5.6 Verification (technical)

`CourseVerifier` uses vision (and optional helpers) against criteria built from the goal’s **`doneWhen`** (and related success fields):

| Status | Meaning (product sense) |
|--------|-------------------------|
| **pass** | Outcome is visibly done |
| **partial** | Progress is real; may still advance with notes (implementation can treat as pass with reason) |
| **offTrack** | Not done — re-coach with what’s missing |

Authors write `doneWhen` in **plain language** describing a durable, visible state:

> *A file named index.html exists in a project folder and opens in a browser showing visible content.*

Never:

> *The user clicked the third icon in the left sidebar of VS Code 1.92.*

### 5.7 Tool policy

Each goal can set **`toolPolicy`**:

| Policy | Behavior |
|--------|----------|
| `pointOnly` | Coach and point only — no driving the Mac for them |
| `preferPointing` | Default bias: point first; tools sparingly |
| `helpWhenStuck` | Tools OK when the learner is stuck |
| `canDoForThem` | “Do it for me” is fully in bounds |

This is how the same engine teaches both **“you must practice clicking”** and **“I’ll unblock you if you’re lost.”**

### 5.8 Memory and tags

During coaching, the model (and runtime) can maintain **per-course learner memory**:

- What they **know** / are **confused by**  
- Preference for hints vs do-it-for-me  
- Optional tags in replies: `[MEMORY:knows:…]`, `[MEMORY:confused:…]` (stripped before speech)  
- `TeachyEngine` extends this toward **skill nodes**, streaks, and cross-course transfer  

### 5.9 Voice and HUD controls

| Input | Typical effect in a course |
|-------|----------------------------|
| Hold **ctrl+option** + speak | Question, advance, skip video, do-it-for-me, teach-back answer |
| Empty hotkey / “I did it” | Confirm your-turn / advance verify |
| Hint | Extra coach turn without advancing |
| Do it for me | Tool-using turn when policy allows |
| Skip (video) | Skip teacher clip |
| Placement / teach-back chips | Structured answers without full voice |

While a course is active, voice is **owned by `LessonPlayer`** (exit phrases carve out). Outside a course, the same hotkey is quick companion Q&A.

### 5.10 TeachyEngine (deeper pedagogy layer)

`leanring-buddy/TeachyEngine/` is the environment-agnostic coaching brain:

| Module | Role |
|--------|------|
| `TeachyEngine.swift` | Coordinates subsystems; session lifecycle |
| `AdapterProtocol.swift` | Contract: learner events in → coaching decisions out (Mac / future browser / CLI) |
| `LearnerModel.swift` | Skills, proficiency, demos, streaks |
| `SkillGraph.swift` | Prerequisites + transfers (e.g. bundled AI fluency graph) |
| `VerificationEngine.swift` | Multi-modal verification depths |
| `TeachBackEngine.swift` | Protégé effect — explain / teach someone else / follow-ups |
| `SpacedRepetitionEngine.swift` | SM-2 style retention scheduling |
| `PortfolioManager.swift` | Capture real artifacts + shareable outcome cards |
| `CoachingSession.swift` | Phases, event log, metrics |

**Design idea:** adapters (macOS UI today) never invent pedagogy; the engine never knows pixels. That keeps a path open to other surfaces without rewriting courses.

---

## 6. How courses are made

### 6.1 What a course is

A course is a **JSON document** (or an equivalent Swift `ClickyCourse` for bundled catalog entries) with:

- Metadata (title, time estimate, outcomes, optional track / prerequisites)  
- Ordered **`goals`**  
- Optional **artifact** description (the thing being built across the path)  
- Optional **teacher videos** (Mux/HLS/mp4 URLs)  

Source of truth for open curriculum: **`courses/*.json`**.  
Bundled app catalog: **`ClickyCourseCatalog`** in `ClickyCourse.swift` (mirrors core paths).  
Installed at runtime: **`~/.teachy/courses/*.json`**.  
Discovery wall: **`academy/registry.json`**.

### 6.2 Authoring workflow (practical)

1. **Copy the template**  
   `courses/_template-with-video-parts.json`

2. **Define the north star**  
   - `title`, `subtitle`, `description`  
   - `learningOutcomes[]` — what they can *do* when finished  
   - Optional `artifact` — initial state → final state of the thing they build  

3. **Break the path into goals**  
   - One goal ≈ one durable win (often 2–8 minutes of work)  
   - Prefer 3–10 goals for a tight path; flagship paths can be longer  

4. **For each goal, write four critical fields**  

   | Field | Purpose |
   |-------|---------|
   | `id` | Stable progress key (never renumber carelessly) |
   | `title` | Short HUD label |
   | `goal` | What success looks like in plain language |
   | `coachAsk` | Natural auto-prompt Teachy sends the vision tutor |
   | `doneWhen` | What vision should see when it’s done |

5. **Add pedagogy (recommended)**  

   ```json
   "teachingContext": {
     "concepts": ["…"],
     "commonMistakes": ["…"],
     "successExamples": ["…"],
     "whyItMatters": "…",
     "teachBackPrompt": "in your words — …?",
     "skipTeachBack": false
   },
   "tips": ["soft hints for the tutor"],
   "toolPolicy": "preferPointing"
   ```

6. **Optional teacher clips (Farza-style)**  
   - Upload parts to Mux / Cloudflare Stream / any HLS or mp4 CDN  
   - Set `teacherVideoURL` on the course and/or each goal  
   - Set `teacherName` for credit on the beside-cursor player  
   - Optional `teacherVideoNotes` — bullets the tutor should internalize after the clip  
   - **Do not** paste normal YouTube *watch* URLs into the course player  

7. **Optional structure**  
   - `startURL` — open a soft homepage once (e.g. `https://github.com/new`)  
   - `trackID` / `trackTitle` / `trackOrder` — multi-part units  
   - `prerequisiteCourseIDs` — soft suggestions, not hard locks  
   - `remediationGoalID` — jump back if they thrash on a hard goal  
   - `artifactDelta` — what this goal changes about the artifact  

8. **Test without rebuilding the app**  
   - Drop the JSON into `~/.teachy/courses/`  
   - Or paste install URL in Learn → Add (GitHub blob links convert to raw)  

9. **Ship**  
   - Commit under `courses/`  
   - Mirror into bundled Swift catalog if it should ship in the DMG  
   - List in `academy/registry.json` for the public wall  
   - Publish Academy with `./scripts/publish-academy.sh` when the site should update  

### 6.3 Goal field reference

| Field | Required | Notes |
|-------|----------|-------|
| `id` | yes | Stable id for progress |
| `title` | yes | Short label |
| `goal` | yes | Durable success description |
| `coachAsk` | yes | Natural tutor prompt |
| `doneWhen` | no* | Strongly recommended — vision gate |
| `tips` | no | Soft hints |
| `teacherVideoURL` | no | Part clip (preferred over legacy `introVideoURL`) |
| `introVideoURL` | no | Legacy alias for the same player |
| `teacherName` | no | Credit on player |
| `teacherVideoNotes` | no | Post-clip coaching notes |
| `teachingContext` | no | Concepts, mistakes, teach-back |
| `toolPolicy` | no | `pointOnly` · `preferPointing` · `helpWhenStuck` · `canDoForThem` |
| `outcome` | no | One-line outcome for HUD |
| `artifactDelta` | no | What changed in the built artifact |
| `remediationGoalID` | no | Fallback goal id on repeated failure |

\* If `doneWhen` is omitted, verification falls back to weaker signals (e.g. user advance). Prefer explicit `doneWhen`.

### 6.4 Authoring rules (non-negotiable)

1. **Never encode UI chrome** — no button names as contracts, no grid cells, no “click pixel (120, 400).”  
2. **Outcomes over procedures** — “repo exists with README on GitHub” beats “click Create repository.”  
3. **One win per goal** — if you need two wins, make two goals.  
4. **`coachAsk` sounds human** — it is fed to the model as a learner request.  
5. **`doneWhen` is visible** — vision must be able to see it on screen.  
6. **Videos teach context; Teachy teaches the doing** — clips are optional prefaces, not the product.  
7. **Test on a messy real Mac** — different browsers, dark mode, half-finished desktops.

### 6.5 Example skeleton

```json
{
  "id": "build-a-website",
  "title": "Build & Deploy a Website",
  "subtitle": "From zero to a live site the world can visit",
  "description": "…",
  "iconSystemName": "display",
  "estimatedMinutes": 45,
  "startURL": "https://github.com/new",
  "teacherName": "Teachy",
  "learningOutcomes": [
    "Write real HTML and CSS",
    "Deploy a live site on GitHub Pages"
  ],
  "artifact": {
    "kind": "website",
    "icon": "globe",
    "initialState": "no files, no site",
    "finalState": "live personal website on GitHub Pages",
    "previewIfNoProgress": "No website yet — let's build one"
  },
  "goals": [
    {
      "id": "plan-your-site",
      "title": "Plan your site",
      "goal": "Decide what the site is about.",
      "coachAsk": "Help me plan a personal website…",
      "doneWhen": "The learner can describe the site in one sentence.",
      "toolPolicy": "pointOnly",
      "teachingContext": {
        "concepts": ["HTML vs CSS"],
        "commonMistakes": ["planning forever, never writing"],
        "successExamples": ["A one-page portfolio about my work"],
        "whyItMatters": "Every line of code has a purpose.",
        "teachBackPrompt": "what is your site about, and who is it for?",
        "skipTeachBack": false
      }
    }
  ]
}
```

Full authoring notes also live in **`courses/README.md`**. World-platform sequencing lives in **`academy/TEACHY_PLAN.md`**.

### 6.6 Tracks (learning paths)

Courses can form **tracks** (Khan-style units):

- `trackID`, `trackTitle`, `trackOrder`  
- Soft `prerequisiteCourseIDs` (e.g. on-ramp before flagship)  

The Learn UI can show “Start here” featured IDs and expand to the full catalog.

### 6.7 Academy install path

1. Course JSON lives in the repo (or any raw URL).  
2. `academy/registry.json` lists metadata + `installURL`.  
3. Learner copies install URL (or uses Learn → Add).  
4. App resolves GitHub blob → raw, downloads into `~/.teachy/courses/`.  

The public website (`academy/index.html`) is also the **marketing + free browser demo** funnel into the Mac app.

---

## 7. Teaching philosophy (product)

Teachy’s pedagogy in one sentence:

> **Short context if needed, then the learner acts on the real system while a vision tutor points, checks, and remembers.**

Supporting principles:

1. **Act-first beats watch-first** — muscle memory comes from doing.  
2. **Pointing is teaching** — spatial guidance on *their* UI beats generic screenshots in a PDF.  
3. **Verify understanding, not attendance** — vision + teach-back > “next slide.”  
4. **Scaffold then fade** — `toolPolicy` and hints let experts fly and beginners not drown.  
5. **Durable goals** — content survives app redesigns.  
6. **Dignity** — plain language; placement checks avoid both condescension and jargon walls.  
7. **Artifacts matter** — a live site, a repo, a shipped video is better proof than a quiz score alone.

---

## 8. Website & go-to-market surface

| Piece | Role |
|-------|------|
| `academy/index.html` | Landing — intro, interactive demo, Get Teachy |
| Free lessons (`quick-github-lesson.html`, etc.) | Browser taste of “coach beside the cursor” without installing |
| `registry.json` | Course discovery metadata |
| `docs/LAUNCH_POSTS.md` | Paste-ready launch copy |
| GitHub Releases | DMG distribution |
| README / Show HN | Developer and builder distribution |

Positioning language: free forever, open source, macOS, **stop watching / start doing**.

---

## 9. Repository map (for humans)

| Path | Purpose |
|------|---------|
| `leanring-buddy/` | macOS app source (product name Teachy) |
| `leanring-buddy/TeachyEngine/` | Adaptive teaching engine |
| `courses/` | Open curriculum JSON |
| `academy/` | Website + registry + free lessons |
| `worker/` | API proxy (local + Cloudflare) |
| `scripts/` | Release DMG, publish Academy |
| `AGENTS.md` | Engineering source of truth for agents |
| `README.md` | Quick start + download |
| `docs/TEACHY.md` | **This document** |

---

## 10. One-page summary

**Teachy** is a free macOS tutor that teaches by **doing on the real screen**.

**How it’s taught:** goal-based courses → optional teacher clip → vision coaching with cursor pointing → learner acts → vision verification → teach-back → memory → next goal.

**How courses are made:** JSON (or bundled Swift) with durable `goal` / `coachAsk` / `doneWhen`, optional video and pedagogy context — never hardcoded UI.

**Goals:** free 1:1 act-first learning; legendary paths; open curriculum; trustworthy, Mac-first platform.

**Potential:** the default practice layer for computer skills — consumer, creator, and eventually classroom — powered by an open engine and a growing catalog of real-world paths.

---

*Last aligned with the Teachy codebase structure in this repo. For implementation detail while coding, prefer `AGENTS.md`. For course JSON field quirks while authoring, prefer `courses/README.md`.*
