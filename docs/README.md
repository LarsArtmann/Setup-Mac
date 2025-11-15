# Documentation Structure

This directory contains all project documentation organized by category.

## Directory Structure

```
docs/
├── architecture/           # System architecture & design docs
├── architecture-understanding/  # Mermaid diagrams & visual architecture
├── complaints/            # Issues discovered during sessions
├── decisions/             # Architecture Decision Records (ADRs)
├── learnings/             # Lessons learned from debugging/sessions
├── operations/            # Operational procedures & manual steps
├── planning/              # Roadmaps & planning documents
├── prompts/               # Reusable debugging/analysis prompts
├── sessions/              # Session summaries (not GitHub issues!)
├── status/                # Status reports from work sessions
└── troubleshooting/       # Known issues & their solutions
```

## Key Documents

### Architecture
- **cross-platform-strategy.md** - macOS → NixOS migration strategy
- **wrapping-system-documentation.md** - Wrapper system architecture
- **network-monitoring-implementation-plan.md** - Monitoring setup

### Operations
- **manual-steps-after-deployment.md** - Post-deployment checklist

### Troubleshooting
- **fish-performance-issue.md** - Fish shell performance debugging
- **fish-shell-activation.md** - Fish activation issues

## Cross-Platform Note

**IMPORTANT:** This setup currently uses Homebrew for some GUI apps on macOS, but is designed for future NixOS migration.

See: `docs/architecture/cross-platform-strategy.md` for:
- Why we use Homebrew on macOS (pragmatic choice)
- How to migrate to NixOS (straightforward)
- Platform package mapping
- Zero reconfiguration needed for migration

**TL;DR:** Using Homebrew NOW doesn't prevent NixOS migration LATER. All packages exist in nixpkgs for Linux.

## Document Naming Convention

Format: `YYYY-MM-DD_HH_MM-descriptive-name.md`

Examples:
- `2025-11-15_10_00-github-issues-comprehensive-organization.md`
- `2025-11-15_07_49-wrapper-template-debugging.md`

## Adding New Documents

1. **Architecture Decision:** → `decisions/YYYY-MM-DD-decision-name.md`
2. **Status Report:** → `status/YYYY-MM-DD_HH_MM-topic.md`
3. **Session Summary:** → `sessions/YYYY-MM-DD_description.md`
4. **Learned Lesson:** → `learnings/YYYY-MM-DD_HH_MM-topic.md`
5. **Reusable Prompt:** → `prompts/YYYY-MM-DD_HH_MM-purpose.md`

## Cleanup Policy

- Keep all status reports (historical record)
- Keep all decisions (architecture history)
- Keep all learnings (institutional knowledge)
- Archive old complaints after resolution
- Update planning docs (don't accumulate)
