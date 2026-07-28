# Teachy Brain

Company knowledge. What Teachy is for, who it's for, how it goes to market, and
how its courses are designed — the reasoning that outlives any particular build.

No code. Nothing here is deployed or imported by anything.

## What's here

| Path | What |
|------|------|
| `docs/TEACHY.md` | what the product is and who it's for |
| `docs/ENTERPRISE.md` | the enterprise story |
| `docs/LAUNCH_POSTS.md` | launch copy |
| `docs/DEMO_SHOT_LIST.md` | demo recording plan |
| `LAUNCH_VIDEO_BRIEF.md` | launch video brief |
| `CHANGELOG.md` | shipped-release history |
| `.cursor/skills/teachy-course-design/` | how a Teachy course is designed — the pedagogy, with examples and reference |

## What lives elsewhere, deliberately

**Engineering design docs** (`docs/design/`) stayed in **teachy-app**. A document
explaining why the Windows sidecar is a separate process is only useful next to
that process; moving it here would separate the decision from the code it
constrains, and it would rot.

**`AGENTS.md`**, the coding-agent guide, also stayed in teachy-app for the same
reason — it describes how to work in that codebase.

The split is roughly: *why we are building this* lives here, *how this code
works* lives with the code.

## Course design

`.cursor/skills/teachy-course-design/` is the one thing here that is directly
operational — it is the standard a new course is written against. Courses
themselves live in teachy-app under `courses/`.

## Repository layout

Teachy is split across three repos:

| Repo | Holds |
|------|-------|
| **teachy-app** | macOS + Windows apps, `courses/`, `connectors/`, the `worker/` proxy |
| **teachy-web** | the Academy site and its deploy config |
| **teachy-brain** (this one) | strategy, launch material, course-design skill |
