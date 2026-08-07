# 0027 — Site is waitlist, not download

**Date:** 2026-08-07
**Status:** accepted
**Affects:** teachy-web funnel, launch messaging, enterprise lead capture

## The question

Should the public Teachy site keep offering Mac installs, or close downloads
and collect interest instead?

## The decision

**Waitlist only for now.** Strip every DMG / “get teachy” / course-install
deeplink from the Academy. Primary CTA is join waitlist: name, email, and
whether they’re personal (“just me”) or company (“my company would love this”).

**No new database.** Submissions go through FormSubmit AJAX to
`ved.06.soni@gmail.com`. Typeform would also work; we skipped it so the form
stays on the comic page instead of bouncing people to a third-party UI.

## Why

The product isn’t ready to invite random downloads. A waitlist still captures
demand and splits consumer vs company interest without standing up Postgres,
Auth, or a form SaaS redesign of the landing page.

## What it costs us

- Signups live in FormSubmit’s email stream (and their retention rules), not a
  sheet or CRM we own — easy to lose track, harder to segment later.
- First FormSubmit delivery needs a one-time confirm on `ved.06.soni@gmail.com`;
  if that inbox filters it, submissions silently fail until we re-point the
  endpoint.
- Anyone with an old release URL can still grab a DMG from GitHub Releases; the
  site just stops advertising it.

## When to revisit

When we reopen public installs, or when waitlist volume needs a real sheet /
CRM (Airtable, Notion, Postgres). Revisit sooner if FormSubmit bounces or spam
shows up.
