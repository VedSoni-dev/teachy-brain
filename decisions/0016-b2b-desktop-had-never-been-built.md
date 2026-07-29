# 0016 — teachy-b2b/desktop had never been compiled; brought to green

**Date:** 2026-07-29
**Status:** accepted
**Affects:** teachy-b2b desktop, course data schema, Mac permission errors

## What was found

`teachy-b2b` is a copy of `teachy-app` made for the B2B line. Going to add the
ACP feature to it surfaced that **it had never been built**: no `node_modules`,
**zero commits** (26 untracked files on a branch with no history), and
`npm run verify` failing on ten TypeScript errors that had nothing to do with the
new work.

The cause was a schema drift nobody could have noticed without compiling.
`src/data/courseGoals.ts` still exported the older `CourseGoal` /
`COURSE_GOALS_BY_ID` shape with an `advanceOnUserConfirm` flag, while
`useCourseSession.ts`, `ProgressTab.tsx` and `courseData.test.ts` had been copied
across already expecting `CourseLearningGoal` / `GOALS_BY_COURSE_ID` with
`doneWhen: string | null`, `teachBackPrompt` and `tips`. Three files importing
names their source never exported — an instant compile error, invisible for as
long as nothing ran the compiler.

## The decision

**Migrate the B2B course file forward; never overwrite it.** The B2B
`ai-fluency-at-work` content is the product — five goals aimed at finishing a real
work task and packaging proof for a manager. Copying `teachy-app`'s file would
have compiled and silently deleted the B2B curriculum.

`advanceOnUserConfirm: true` became `doneWhen: null`, which is exactly how the
session loop reads "advance on the learner's word" (`if (!currentGoal.doneWhen)`).
`teachBackPrompt` is null throughout and `tips` empty — see the gap below.

Result: `teachy-b2b/desktop` passes `npm run verify` for the first time —
typecheck, 136 tests, build.

## Also fixed: macOS reported a permission problem as a crash

The Mac smoke path (`TEACHY_MAC_SMOKE=1`) exited 1 ("broken") when Screen
Recording was merely ungranted. `macHost.captureScreen` threw a helpful message
when `desktopCapturer.getSources()` returned an **empty list** — but macOS never
does that. It makes Electron throw `Failed to get sources.`, which sailed past the
handler untouched.

So the actionable message was written for a case that cannot happen, and the case
that does happen surfaced Electron's internal wording. That raw string is what a
first-run learner saw, which is the same failure as the already-recorded "raw
error strings spoken to learners". `getSources()` is now wrapped and both paths
produce one message naming System Settings → Privacy & Security → Screen
Recording. The smoke path now correctly exits 2 (`NEED_PERMISSION`).

Fixed in both repos.

## What it costs us

- **The B2B course has no teach-back prompts and no author tips.** Both fields are
  schema-valid as null/empty and the code guards for it, so nothing breaks — but
  the "stuck" hint has no author tips to draw on, and no goal offers a soft
  teach-back. That is content authoring, deliberately not invented here.
- **`teachy-b2b` still has zero commits.** Everything is untracked working tree.
  One `rm -rf` and the B2B line is gone.
- **Two near-identical desktop codebases.** The ACP port was ten file copies
  because the trees are otherwise the same, which is convenient today and the
  reason this schema drift existed at all.

## When to revisit

If a third copy of `desktop/` is ever proposed, extract the shared renderer
instead. Two is already how this bug happened.
