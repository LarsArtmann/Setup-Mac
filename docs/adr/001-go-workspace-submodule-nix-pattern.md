# ADR-001: Go Workspace Sub-Module Nix Pattern

**Date:** 2026-05-08
**Status:** Accepted

## Context

The `go-output` library restructured into Go workspace sub-modules (`enum`, `escape`, `table`, `sort`), each with its own `go.mod`. When Nix builds downstream packages (e.g., `file-and-image-renamer`), only the root `go-output-src` path is provided as a `replace` directive. Go's module loader cannot resolve the sub-modules, causing `go mod vendor` to fail.

## Decision

Use `require` + `replace` directives for each sub-module in `postPatch`. Both are needed — `replace` alone isn't sufficient because Go needs `require` to know the module exists in the dependency graph.

Centralized into `lib/go-output-submodules.nix` to avoid duplicating the sub-module list in every downstream package.

## Consequences

- If `go-output` adds new sub-modules, only `lib/go-output-submodules.nix` needs updating
- Downstream packages import the helper and get consistent behavior
- The correct upstream fix is publishing proper Go modules with tagged versions, but that's outside our control
