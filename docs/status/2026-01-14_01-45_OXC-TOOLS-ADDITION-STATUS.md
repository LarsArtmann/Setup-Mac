# Oxc Tools Addition Status

**Date**: 2026-01-14 01:45 UTC
**Status**: Partially Complete (2/3 tools)

## Summary

Successfully added two Oxc project tools to the Nix configuration:
- ✅ **oxlint** - Fast JavaScript/TypeScript linter (Rust-based)
- ✅ **tsgolint** - TypeScript-aware linter for oxlint (Go-based)

## Tools Added

### 1. oxlint
- **Purpose**: Ultra-fast JavaScript/TypeScript linter
- **Language**: Rust
- **Status**: ✅ Available in nixpkgs, added to `developmentPackages`
- **Version**: Latest from nixpkgs-unstable
- **Location**: `platforms/common/packages/base.nix`

### 2. tsgolint
- **Purpose**: Type-aware linting for oxlint
- **Language**: Go
- **Status**: ✅ Available in nixpkgs, added to `developmentPackages`
- **Version**: 0.11.0
- **Dependency**: Required by oxlint for type-aware linting
- **Location**: `platforms/common/packages/base.nix`

## Tools Not Added

### 3. oxfmt
- **Purpose**: Fast JavaScript/TypeScript formatter (Prettier-compatible)
- **Language**: Rust
- **Status**: ❌ NOT available in nixpkgs
- **Reason**: Custom package would require Cargo.lock vendoring and maintenance

## Why oxfmt Was Not Added

The oxfmt tool is NOT available in nixpkgs yet. To add it via Nix would require:

1. **Custom Package Creation**:
   ```nix
   # Example (not implemented)
   rustPlatform.buildRustPackage rec {
     pname = "oxfmt";
     version = "0.24.0";
     src = fetchFromGitHub {
       owner = "oxc-project";
       repo = "oxc";
       rev = "v${version}";
       hash = "...";  # Requires cargo hash
     };
     cargoHash = "...";  # Requires Cargo.lock hash
     # Additional configuration needed...
   }
   ```

2. **Maintenance Overhead**:
   - Need to track Cargo dependencies
   - Need to update hash on every version bump
   - Requires vendor hash for offline builds
   - Not aligned with "declarative via nixpkgs" philosophy

3. **Alternatives**:
   - **Use via npm/bun**: `bun add -D oxfmt` (preferred for current workflow)
   - **Wait for nixpkgs**: Monitor for when oxfmt is added upstream
   - **Create flake input**: Add separate flake input for oxc-project releases

## Configuration Changes

### Modified Files
- `platforms/common/packages/base.nix`

### Changes Made
```nix
# Added to developmentPackages section:
oxlint      # Fast JS/TS linter
tsgolint    # Type-aware linting support
```

## Verification Plan

1. **Wait for current rebuild** to complete
2. **Open new terminal** to refresh PATH
3. **Verify tools are available**:
   ```bash
   which oxlint
   which tsgolint
   ```
4. **Test basic functionality**:
   ```bash
   oxlint --version
   tsgolint --version
   ```

## Next Steps

### Immediate
1. Complete current rebuild (if not done)
2. Verify oxlint and tsgolint installation
3. Test linter functionality

### Future (oxfmt)
1. Monitor nixpkgs for oxfmt addition
2. Consider creating PR to add oxfmt to nixpkgs
3. Or use oxfmt via npm/bun for development

## Benefits of This Addition

### oxlint
- **50-100x faster** than ESLint
- **570+ rules** out of the box
- **Zero configuration** needed for basic use
- **Type-aware** when combined with tsgolint

### tsgolint
- Enables **true type-aware linting** for oxlint
- Built from **oxc-project/tsgolint** Go package
- Automatically **wrapped** by oxlint for easy use

## Architecture Alignment

✅ **Follows established patterns**:
- Tools added to `developmentPackages` in `base.nix`
- Cross-platform (macOS and NixOS)
- No platform-specific configuration needed
- Maintains declarative package management via nixpkgs

❌ **oxfmt decision rationale**:
- Custom packages create maintenance burden
- Not in nixpkgs (unlike oxlint and tsgolint)
- Better to use via npm/bun for now
- Aligns with "use nixpkgs when possible" principle

## Testing Status

- [x] oxlint package available in nixpkgs
- [x] tsgolint package available in nixpkgs
- [ ] Build configuration test (in progress)
- [ ] Tools installed in PATH (waiting for rebuild)
- [ ] Basic functionality test
- [ ] Integration with existing development workflow

## Notes

- oxlint **automatically includes** tsgolint in its PATH for type-aware linting
- Both tools are part of the **oxc-project** monorepo
- Tools are actively maintained and regularly updated
- oxlint version 1.38.0+ includes significant improvements
- tsgolint version 0.11.0 is the latest as of this writing

---

**Decision**: Added oxlint and tsgolint (available in nixpkgs), skipped oxfmt (not in nixpkgs).
**Rationale**: Maintain declarative, low-maintenance architecture using official nixpkgs packages.
