# Reusable Prompt: Nix Build Error Debugging

**Name:** Nix Build Error Systematic Debugging
**Created:** 2025-11-15
**Context:** When `just switch` or `nix build` fails with evaluation errors
**Success Rate:** High (resolved 3/4 errors in one session)

---

## Prompt

```
I'm getting a Nix build error. Please help me debug it systematically.

CONTEXT:
- System: macOS with nix-darwin
- Build tool: nh darwin switch OR darwin-rebuild switch
- Error occurs during: [evaluation | building | activation]

ERROR OUTPUT:
[paste full error output here, especially the bottom 50 lines]

REQUIREMENTS:
1. Identify root cause by analyzing error trace backwards
2. Check if it's a common Nix pattern issue (module system, function signatures, etc.)
3. Propose 2-3 solutions with trade-offs
4. Ask clarifying questions if needed before implementing
5. Make incremental fixes with git commits
6. Test with `nix build --dry-run` after EACH fix
7. Document the fix in commit message

PROCESS TO FOLLOW:
1. Analyze error trace from bottom up
2. Identify the problematic file and line number
3. Read that file to understand context
4. Check for common anti-patterns:
   - Self-referencing config in plain Nix files
   - Function signature mismatches
   - Missing package dependencies
   - Broken packages in nixpkgs
5. Propose solutions with pros/cons
6. Wait for my decision before implementing
7. Implement incrementally with commits
8. Validate each fix with dry-run

DO NOT:
- Disable functionality without asking first
- Batch multiple fixes without testing between
- Assume I want the "quick fix" over the "right fix"
- Skip documentation

EXPECTED OUTPUT FORMAT:
1. Root Cause Analysis (2-3 sentences)
2. Options (2-3 approaches with trade-offs)
3. Recommendation (with reasoning)
4. Implementation Plan (step-by-step)

Ready? Here's my error:
[paste error]
```

---

## Usage Example

**User Input:**

```
I'm getting this error when running `just switch`:

error: undefined variable 'config'
at /path/to/WrapperTemplate.nix:46:30
```

**AI Response:**

```
ROOT CAUSE:
WrapperTemplate.nix uses `config` self-reference in a lib.types.submodule
option definition. This only works within NixOS module evaluation context,
but this file is imported directly as plain Nix.

OPTIONS:
1. Remove self-reference, compute at runtime (RECOMMENDED)
   Pro: Proper separation of schema vs logic
   Con: Slightly more verbose

2. Convert to full module (use in module imports)
   Pro: Can use config self-reference
   Con: More complex, overkill for this use case

3. Use function default parameters
   Pro: Simple
   Con: Less type-safe

RECOMMENDATION: Option 1 - compute wrapperName in function body

IMPLEMENTATION:
1. Change wrapperName type to `nullOr str` with `default = null`
2. Add computation in wrapWithConfig: `wrapperName = cfg.wrapperName or "wrapped-${cfg.packageName}"`
3. Update all references to use computed value
4. Test with dry-run
5. Commit with detailed message

Shall I proceed with Option 1?
```

---

## Variations

### For Dependency Issues:

```
Error involves broken package (marked as broken in nixpkgs).

Add this requirement:
- Evaluate Homebrew alternative if available
- Consider package override with broken flag
- Check if different version works
```

### For Performance Issues:

```
Build succeeds but system is slow.

Add this requirement:
- Benchmark before and after changes
- Check for wrapper overhead
- Analyze shell startup times
```

### For Type Errors:

```
Error about type mismatches or unexpected arguments.

Add this requirement:
- Audit all function signatures involved
- Check import statements match function definitions
- Verify lib.types usage is correct
```

---

## Success Criteria

After following this prompt, you should have:

- ✅ Clear understanding of root cause
- ✅ 2-3 evaluated options
- ✅ Incremental git commits with detailed messages
- ✅ Dry-run test passing
- ✅ Documentation of the fix

---

## Related Prompts

- **nix-package-migration.md** - For migrating Homebrew to Nix
- **wrapper-creation.md** - For creating new wrapper packages
- **system-architecture-review.md** - For broader architectural analysis

---

## Template Variables

Customize for your specific case:

- `[system-type]`: macOS, NixOS, etc.
- `[build-command]`: nh darwin switch, darwin-rebuild, etc.
- `[error-type]`: evaluation, building, activation
- `[paste error]`: Your actual error output
