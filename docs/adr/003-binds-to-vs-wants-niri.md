# ADR-003: BindsTo vs Wants for Niri Service

**Date:** 2026-05-08
**Status:** Accepted

## Context

Upstream niri.service uses `BindsTo=graphical-session.target`. During `just switch`, the graphical target restarts, which kills niri (BindsTo semantics). This disrupts the entire desktop session during config switches.

## Decision

Replace `BindsTo` with `Wants` in the niri service unit. `Wants` pulls in the target (activating waybar etc.) without the hard binding — niri survives target restarts.

## Consequences

- `just switch` no longer kills the compositor
- Niri still starts with the graphical session on boot
- Side services (waybar, etc.) still activate via target dependency
