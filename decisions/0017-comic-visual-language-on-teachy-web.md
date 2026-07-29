# 0017 — Comic visual language on teachy-web (not HeyClicky glass)

**Date:** 2026-07-29
**Status:** accepted
**Affects:** teachy-web academy landing (`index.html`, `styles.css`)

## The decision

The consumer landing drops the HeyClicky / Frutiger Aero / iMessage look.
Visual language is **comic panels**: ink outlines, hard offset shadows, flat
fills, speech balloons with pointed tails, sticker buttons. Logos wall and
copy stay. Body text uses Nunito (not SF Pro); bubble dialogue uses Baloo 2.

Scoped under `body.comic-page` so enterprise / other pages are untouched until
we deliberately extend them.

## Why

The site read as a HeyClicky clone with Apple Messages bubbles. Teachy needs
its own face — playful tutor energy, not glass SaaS.

## What it costs us

We lose the polished aqua/glass familiarity that some visitors associate with
"premium mac app." Comic ink can look louder on secondary pages if we don't
keep enterprise calmer. Overlapping CSS passes in `styles.css` make future
overrides fragile until a cleanup pass. BAM/SPLAT stamps add motion that
reduced-motion users skip (handled) — sighted users may find the chat row busy.

## When to revisit

If brand feedback asks for quieter enterprise parity, or when `styles.css`
gets a real redesign (collapse the stacked "HEY REDESIGN" layers).
