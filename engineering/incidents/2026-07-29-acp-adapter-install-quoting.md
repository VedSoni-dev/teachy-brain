# `cmd /s` ate a quote and the ACP adapter could never install on Windows

**Date:** 2026-07-29
**Severity:** feature unreachable on one platform, with a misleading error
**Found by:** running the app on Windows for the first time — the whole suite was green

## What happened

First Windows run of the borrowed-subscription flow. Settings offered **Install
the ACP adapter**, the learner pressed it, and got:

> 'C:\Program' is not recognized as an internal or external command, operable
> program or batch file.

Nothing about the adapter, npm, or what to do. The button never worked, so
[0015](../../decisions/0015-borrow-a-subscription-over-acp.md) was unreachable on
Windows regardless of subscription.

## Root cause

npm's global shim on this box is `C:\Program Files\nodejs\npm.cmd`. `spawn()`
cannot execute a `.cmd`, so `locator.buildSpawnArgs` routed it through the
command processor and produced:

```
cmd /d /s /c "C:\Program Files\nodejs\npm.cmd" install -g @agentclientprotocol/claude-agent-acp
```

`/s` means: strip the **first and last quote character** of everything after
`/c`, then run what remains. Only the executable was quoted, so its own closing
quote was the last quote on the line. cmd removed both and ran:

```
C:\Program Files\nodejs\npm.cmd install -g ...
```

Unquoted, that splits at the space, and cmd tries to execute `C:\Program`.

The fix is one more pair of quotes around the *whole* command line, so `/s` has
something to strip that is not load-bearing — which is exactly what cross-spawn
does and why:

```
cmd /d /s /c ""C:\Program Files\nodejs\npm.cmd" install -g ..."
```

Confirmed by running all three variants against a real cmd.exe: the old form
exits 1 with the error above, the new form exits 0 and prints the npm version.

## Why the tests did not catch it

They asserted the *shape* of the argument array, and the shape was fine — path
quoted, arguments after it, correct flags. One test was even named "quotes the
path so spaces in the profile name survive", and it passed against the broken
code.

The bug was never in our array. It was in how **cmd.exe parses** that array. No
assertion about our own data structure can reach a bug in someone else's parser.

`buildSpawnArgs` takes `platform` as a parameter specifically so the Windows
branch is checkable from a Mac, and that was the right instinct — it just bought
less than it looked like. Platform-parameterised unit tests prove we *build* what
we meant to. They cannot prove the OS *agrees* with what we meant.

## What changed

- The whole command line is wrapped, and arguments containing spaces are quoted
  (custom harnesses pass `node "<path>" --acp`, same failure).
- `packages/core/tests/acpSpawnWindows.test.ts` — writes a real `.cmd` under a
  directory with a space, runs it through a **real cmd.exe**, and asserts the
  output. Skipped off Windows. It fails against the old code.
- Windows fallback lookup now includes `~/.npm-global`, the common custom npm
  prefix. Without it Teachy installs the adapter successfully and then reports it
  missing — the worst shape, since the one-tap fix is the thing that just ran.

## What this unblocked

The first real ACP turn ever completed on Windows, against a live Claude Max
session, driving the app's own `locator.cjs` and `connection.cjs`:

```
[adapterPath] C:\Users\vedan\.npm-global\claude-agent-acp.cmd
[initialize]  protocolVersion 1, promptCapabilities {image:true, embeddedContext:true}
[stopReason]  end_turn
```

Streamed text arrived chunked (`"T"`, then `"EACHY_ACP_OK"`).

## The lesson worth keeping

When code exists only to satisfy another program's parser — a shell, a command
processor, a regex engine — the test has to run that program. Everything else is
a test of our opinion about it.
