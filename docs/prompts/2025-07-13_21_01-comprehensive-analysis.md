# Reusable Prompts for Future Development Sessions

## 1. Comprehensive System Analysis

**Name**: `comprehensive-system-analysis`

**Prompt**:
```
Perform a comprehensive analysis of this codebase/system including:

1. REFLECTION PHASE:
   - What architectural decisions cause problems now?
   - What ghost systems exist (configured but unused, commented code, broken integrations)?
   - Which tools/patterns are over-engineered vs under-engineered?
   - What could be simplified or consolidated?

2. ANALYSIS USING 5 PARALLEL AGENTS:
   - Agent 1: Architecture and design patterns
   - Agent 2: Configuration management and automation
   - Agent 3: Issue tracking and project management
   - Agent 4: Documentation structure and quality
   - Agent 5: Integration issues and ghost systems

3. EXECUTION PLAN CREATION:
   - Sort all tasks by impact vs effort (high impact, low effort first)
   - Break into 30-100min tasks, then further into 12min micro-tasks
   - Include specific time estimates and priority ratings
   - Consider existing code reuse before implementing from scratch

4. IMPLEMENTATION REQUIREMENTS:
   - Quick wins first (implement immediately if under 15 minutes)
   - Create comprehensive documentation structure
   - Update project management system (GitHub issues)
   - Remove ghost systems and fix broken integrations
   - Respect user preferences (check their configuration/preferences first)

5. DOCUMENTATION DELIVERABLES:
   - Architecture understanding (current and improved)
   - Learnings document for future reference
   - Complaints/missing information report
   - Reusable prompts for similar situations

Execute with bias toward action on clear improvements while documenting thoroughly for future reference.
```

## 2. Ghost System Detection and Cleanup

**Name**: `ghost-system-cleanup`

**Prompt**:
```
Identify and clean up ghost systems in this project. Look for:

GHOST SYSTEMS TO FIND:
- Empty or placeholder files (0 bytes, TODO comments only)
- Configured but not installed tools (config files without actual setup)
- Commented-out code that should be removed vs preserved
- Backup files, duplicate implementations, unused dependencies
- Broken symlinks, outdated references, orphaned configurations

DETECTION STRATEGY:
- Search for empty files, backup files, placeholder patterns
- Check that configured tools are actually installed/working
- Identify redundant implementations of same functionality
- Verify integrations actually work as configured
- Find configurations that reference non-existent files

CLEANUP APPROACH:
- Remove obvious ghost files (empty placeholders, old backups)
- Fix broken integrations (install configured tools)
- Choose primary implementations, deprecate redundant ones
- Update references to removed/moved files
- Document any preserved comments with rationale

SAFETY MEASURES:
- Use 'trash' instead of 'rm' if available
- Commit cleanup in small, atomic changes
- Test integrations after fixing
- Document what was removed and why

Report findings before making changes if ghost systems are unclear.
```

## 3. GitHub Issue Management Workflow

**Name**: `github-issue-management`

**Prompt**:
```
Manage GitHub issues systematically:

ISSUE AUDIT PROCESS:
1. Get complete issue list: `gh issue list -L 700`
2. Categorize issues by actionability:
   - CLOSE: Empty body, vague questions without context, completed work
   - IMPLEMENT: Clear requirements, ready for work, quick wins
   - UPDATE: Need status comments, progress updates, or clarification
   - TRACK: Long-term goals, tracking issues, complex features

IMPLEMENTATION PRIORITY:
- Quick wins under 15 minutes: implement immediately
- Well-defined issues with clear acceptance criteria: high priority
- Vague issues needing clarification: request details or close
- Completed work: close with implementation details

ISSUE MANAGEMENT ACTIONS:
- Close issues with explanatory comments about why
- Implement quick wins and close with implementation details
- Comment on issues with status updates and progress
- Create new issues for discovered work not tracked
- Update tracking issues with current progress

COMMUNICATION STANDARDS:
- Provide implementation details when closing issues
- Include commit references for completed work
- Explain closure reasons for vague/outdated issues
- Update issue descriptions with current status if needed

Focus on rapid cleanup of obvious issues while implementing clear quick wins.
```

## 4. Configuration Management Modernization

**Name**: `config-modernization`

**Prompt**:
```
Modernize configuration management with focus on:

ASSESSMENT AREAS:
1. Package Management Strategy:
   - Identify dual package manager usage (Nix + Homebrew + others)
   - Find packages that should migrate to primary system
   - Detect dependency conflicts and resolution strategy

2. Configuration Consolidation:
   - Look for scattered configuration (manual files vs declarative)
   - Identify Home Manager or similar opportunities
   - Find environment variable conflicts (multiple PATH definitions)

3. Integration Validation:
   - Test that configured tools actually work
   - Verify symlinks point to existing files
   - Check that automation scripts are functional

MODERNIZATION PRIORITIES:
- Enable declarative configuration management (Home Manager, etc.)
- Consolidate environment variable management
- Remove manual processes that can be automated
- Migrate to primary package manager where possible
- Fix broken integrations and remove unused configurations

IMPLEMENTATION APPROACH:
- Start with broken integrations (highest impact)
- Move to consolidation opportunities
- Implement automation for manual processes
- Test thoroughly after each change
- Document migration rationale and rollback procedures

Keep existing working systems functional while gradually improving.
```

## 5. Architecture Documentation Generator

**Name**: `architecture-documentation`

**Prompt**:
```
Create comprehensive architecture documentation for this project:

DOCUMENTATION REQUIREMENTS:
1. Current Architecture Analysis:
   - Component relationships and data flow
   - Technology stack and dependencies
   - Integration points and external services
   - Patterns and architectural decisions

2. Architecture Diagrams (Mermaid):
   - System overview with major components
   - Data flow and event handling
   - Command/Query separation if applicable
   - Deployment and infrastructure view

3. Decision Documentation:
   - Technology choices and rationale
   - Pattern selections (DDD, CQRS, etc.)
   - Trade-offs and alternatives considered
   - Future architectural direction

4. Improvement Recommendations:
   - Architectural debt and technical debt
   - Scalability and maintainability improvements
   - Integration and deployment optimizations
   - Performance and security considerations

DELIVERABLE STRUCTURE:
- /docs/architecture/overview.md - System overview
- /docs/architecture/current.mmd - Current architecture diagram
- /docs/architecture/improved.mmd - Proposed improvements
- /docs/decisions/ - Architectural Decision Records
- /docs/development/setup.md - Developer onboarding

Focus on practical documentation that helps developers understand and contribute to the system.
```

## 6. Performance Analysis and Optimization

**Name**: `performance-optimization`

**Prompt**:
```
Analyze and optimize system performance:

MEASUREMENT PHASE:
- Establish baselines with quantitative tools (hyperfine, etc.)
- Identify performance bottlenecks and pain points
- Measure startup times, command execution, build times
- Document current performance characteristics

OPTIMIZATION STRATEGIES:
- Lazy loading and async operations
- Caching strategies and cache invalidation
- Dependency optimization and removal
- Configuration tuning and environment optimization

IMPLEMENTATION APPROACH:
- Start with highest-impact, lowest-effort optimizations
- Implement one change at a time with measurement
- Document performance improvements with before/after metrics
- Create automated performance regression testing

VALIDATION REQUIREMENTS:
- Quantitative measurement of improvements
- Ensure changes don't break existing functionality
- Document performance targets and acceptable ranges
- Create monitoring for performance regression detection

Report percentage improvements and absolute time savings to demonstrate impact.
```

## Usage Guidelines

### When to Use These Prompts
1. **comprehensive-system-analysis**: Starting analysis of complex projects
2. **ghost-system-cleanup**: Regular maintenance or when noticing unused files
3. **github-issue-management**: Periodic issue cleanup or after major releases
4. **config-modernization**: When configuration becomes unwieldy or fragmented
5. **architecture-documentation**: New team members or major system changes
6. **performance-optimization**: When system feels slow or for regular optimization

### Customization Tips
- Adjust time estimates based on project complexity
- Modify analysis agents based on project type (frontend, backend, infrastructure)
- Adapt tool preferences to match project conventions
- Scale scope based on available time and priorities

### Success Metrics
- Reduced maintenance burden
- Faster development workflows
- Better documentation coverage
- Fewer integration issues
- Improved performance characteristics
- Higher team productivity

These prompts encode the successful patterns from this comprehensive analysis session for reuse in future projects.