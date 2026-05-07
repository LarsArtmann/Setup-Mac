# ADR-004: PartOf vs BindsTo for Wallpaper Services

**Date:** 2026-05-08
**Status:** Accepted

## Context

The awww wallpaper daemon crashes on BrokenPipe (upstream bug in 0.12.0). The wallpaper service must survive daemon crashes and restore state after daemon recovery.

## Decision

Use `PartOf=["awww-daemon.service"]` for the wallpaper service. `PartOf` propagates restarts (wallpaper restarts when daemon restarts) without killing the wallpaper service when the daemon crashes. Never use `BindsTo` — it kills the wallpaper service on daemon crash, preventing recovery.

## Consequences

- On daemon crash recovery: `awww restore` restores last displayed image
- No wallpaper loss during daemon instability
- Self-healing architecture without bash supervisor loops
