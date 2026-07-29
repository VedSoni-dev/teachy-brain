# 0011 — Mac ships the Electron/React shell too

**Date:** 2026-07-28
**Status:** accepted
**Affects:** teachy-app desktop, macOS distribution path

## The question

macOS Teachy is a native SwiftUI app. Windows is Electron + React + a C# sidecar.
Shipping to Aggie Innovators needs **one UI**. Do we keep dual-maintaining, or
make Mac run the React shell?

## The decision

**Mac runs the same Electron + React desktop as Windows.** OS work goes through
an in-process `MacSidecarHost` that speaks the Windows sidecar's command/event
surface (`capture-screen`, config, progress, speak, PTT events).

The Swift app stays in the tree for Sparkle-shipped installs and as a reference
implementation. New coaching UI work happens in `desktop/`.

## Why

- The renderer already owns prompts, courses, pointing, verification.
- Dual AI logic (Swift + TS) is the failure mode named in
  [0003](0003-windows-is-electron-plus-a-csharp-sidecar.md).
- TAMU rollout cares that the loop works, not that the notch is NSPanel-native.

## What it costs us

- Mac feel is worse than SwiftUI (click-through, Spaces, hold-to-talk).
- PTT on Mac is Ctrl+Option+Space toggle until a CGEvent hold-hook lands; typed
  Ask works immediately.
- Screen Recording permission must be granted to Electron/Teachy.
- Agent "click for me" tools are stubbed on Mac until Accessibility is wired.

## When to revisit

If Aggies bounce because the shell feels "not Mac," or if hold-to-talk + AX
automation become the product — then invest in the Mac host depth, not a second
Swift UI.
