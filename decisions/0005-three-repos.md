# 0005 — Three repos: app, web, brain

**Date:** 2026-07-28
**Status:** accepted
**Affects:** everything

## Decision

The single `VedSoni-dev/teachy` repo split into three, each keeping the commits
that touched its own files (via `git filter-repo`, so `blame` and `log` still
work):

| Repo | Holds |
|------|-------|
| **teachy-app** | macOS + Windows apps, `courses/`, `connectors/`, `worker/` |
| **teachy-web** | the Academy site and its deploy config |
| **teachy-brain** | this repo — strategy, decisions, launch, course design |

The original repo stays untouched as an archive.

## Where the lines fell, and why

The rule is: **why we are building this** lives in brain, **how this code works**
lives with the code.

So `docs/design/` — engineering design documents — stayed in teachy-app. A
document explaining why the Windows sidecar is a separate process is only useful
next to that process; filing it here would separate a decision from the code it
constrains, and it would rot within a release. `AGENTS.md` stayed for the same
reason.

Shared content (`courses/`, `connectors/`, `worker/`, `scripts/`) went to the app.
The app bundles courses; the website only references them by URL, so there is no
build coupling to break.

## The coupling that survived

`teachy-web`'s `academy/registry.json` installs courses by raw URL out of the app
repo. That is a real dependency across a repo boundary and it **fails silently**:
if the URL points at a stale repo, the app installs an old course and nothing
errors. It is written into teachy-web's README so it does not get lost.

## Cost accepted

Three repos means three checkouts, three CI setups, and cross-repo changes that
no longer land in one commit. That is worth it here because the three have
genuinely different audiences and release rhythms: the app ships versioned
binaries, the site deploys continuously, and the brain is read by humans and
agents rather than built at all.

## See also

- Each repo's README documents the split from its own side.
