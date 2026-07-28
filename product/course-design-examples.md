# Example: Make a Website

Canonical application of `teachy-course-design`.

## Trophy

A live `*.vercel.app` URL they can text someone.

## HAVE situations used

| id | First move |
|----|------------|
| nothing | Interview → ChatGPT plan |
| ai-files | Open files, own the HTML, then plan/polish |
| design | Use mock; skip image gens |
| old-platform | Copy copy; rebuild one page |
| repo | Jump toward build/ship |
| domain | Ship vercel.app first; DNS later |

## Happy path (implemented)

| Goal id | Title | Notes |
|---------|-------|-------|
| `intake` | Figure out your path | `advanceOnUserConfirm` |
| `write-the-prompt` | Plan in ChatGPT | Interview + open + paste **one goal**; `canDoForThem` |
| `mock-landing` | Mock the landing | Free gens ~2–3/day; landing first |
| `build-it` | Build it | Replit vs agent via intake memory |
| `ship-on-vercel` | Ship on Vercel | Custom domain after |

## Agent routing (as shipped)

Cursor → Cursor · Claude → Claude Code · ChatGPT → Codex/ChatGPT · unpaid → Codex free · willing to pay → Claude Code · vibe → Replit

## Active-prompter beat (the magic)

1. Ask context questions one at a time  
2. Write the perfect ChatGPT prompt from answers  
3. Open `https://chatgpt.com` and paste — same turn  
4. Learner says "plan is good" → next step  

If they say next step before ChatGPT is open, LessonPlayer forces open+paste (do not soft-pass past this).

## Files

- Design: `docs/design/2026-07-24-make-a-website.md`
- Tree canvas: `website-course-decision-tree.canvas.tsx` (Cursor canvases folder)
- Swift: `ClickyCourseCatalog.buildAWebsiteCourse`
- JSON: `courses/build-a-website.json`

## How to replicate for a new topic

1. Replace trophy (e.g. "a working Claude project that does X")  
2. Rewrite HAVE table for that domain  
3. Keep intake shape + active-prompter plan beat  
4. Swap build/ship tools (still open links for them)  
5. Design doc → implement → dogfood Phase 0–1  

Do not copy HTML/CSS goals. Copy the **shape**.
