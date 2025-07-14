# Reusable Prompt: Claude Configuration Modernization

Date: 2025-07-14T09:04:25+02:00
Purpose: Standardized prompt for Claude configuration and development tool modernization projects

## Prompt Template

```
I need help modernizing and optimizing my development configuration setup. Please analyze the current state and provide comprehensive improvements following these guidelines:

### Project Context
- **Target Environment**: [macOS/Linux/Windows]
- **Primary Development Languages**: [Go/TypeScript/Python/etc]
- **Configuration Management**: [Nix/Homebrew/Manual/Mixed]
- **Current Pain Points**: [Slow startup/Broken integrations/Maintenance overhead/etc]

### Analysis Requirements

#### 1. Architecture Assessment
- Evaluate current configuration architecture using Domain-Driven Design principles
- Identify over-engineering vs. under-engineering patterns
- Assess tool integration quality and maintainability
- Document architecture decisions and their consequences

#### 2. Ghost System Detection
- Identify configured but non-functional tools
- Find empty placeholder files and broken symlinks
- Detect unused dependencies and conflicting configurations
- Assess pre-commit hooks and integration completeness

#### 3. Performance Analysis
- Benchmark current shell startup times and tool performance
- Identify bottlenecks and optimization opportunities
- Measure impact of proposed improvements
- Document before/after performance metrics

#### 4. Integration Validation
- Test all configured tools for actual functionality
- Verify package manager consistency (Nix/Homebrew/etc)
- Validate environment variable and PATH configurations
- Check pre-commit hooks and automation setup

### Architecture Preferences

#### Go Development (PRIMARY BACKEND)
- **Framework**: fiber or gin for web applications
- **Templates**: templ for type-safe HTML generation
- **Database**: sqlc for type-safe SQL with golang-migrate
- **CLI**: cobra for command-line interfaces
- **Config**: viper for configuration management
- **Logging**: slog or zap for structured logging
- **Testing**: testify for unit tests, godog for BDD scenarios
- **Observability**: OpenTelemetry for tracing and metrics
- **Utilities**: samber/lo for functional programming patterns

#### Frontend Development (HTMX-FIRST)
- **Interactivity**: HTMX for server-side rendered applications
- **Styling**: TailwindCSS for utility-first CSS
- **JavaScript**: Alpine.js for lightweight client-side interactions
- **Components**: Web Components for reusable UI elements
- **TypeScript**: For complex client-side applications when needed

#### Configuration Management
- **Package Management**: Prefer Nix over Homebrew for reproducibility
- **Dotfiles**: Home Manager for declarative configuration
- **Shell**: Optimized for fast startup with async loading
- **Git**: git town for enhanced branch management
- **Task Runner**: just for project automation

#### Tool Preferences
- **File Operations**: trash instead of rm for safety
- **Package Manager**: Bun over npm for JavaScript projects
- **Search**: ripgrep (rg) for fast text search
- **Fuzzy Finding**: fzf for file and command discovery
- **Performance**: hyperfine for benchmarking
- **Git UI**: gh for GitHub CLI operations

### Implementation Guidelines

#### Development Patterns
- **Functional Programming**: Prefer immutability and pure functions
- **Type-First Development**: Make impossible states unrepresentable
- **Small Functions**: Single responsibility, 1-150 lines maximum
- **Early Returns**: Avoid nested conditionals
- **Explicit Over Implicit**: Clear function signatures and behavior

#### Code Organization
- **Domain-Driven Structure**: Organize by business capability
- **Clear Module Boundaries**: Explicit interfaces between components
- **Atomic Commits**: Small, focused commits with clear messages
- **Test-Driven Development**: Write tests for critical functionality
- **Documentation**: Code should be self-documenting with minimal comments

#### Performance Priorities
- **Measure First**: Establish baselines before optimization
- **Cache Expensive Operations**: Reduce repeated computation
- **Lazy Loading**: Defer initialization until needed
- **Parallel Processing**: Use concurrency for I/O-bound operations

### Deliverables Required

#### 1. Current State Analysis
- **Architecture Diagram**: Visual representation of current setup
- **Ghost System Report**: List of non-functional configurations
- **Performance Baseline**: Current startup times and bottlenecks
- **Integration Status**: Which tools work vs. need fixing

#### 2. Improvement Plan
- **Priority Matrix**: Sort improvements by impact/effort/value
- **Migration Strategy**: Step-by-step modernization plan
- **Risk Assessment**: Potential issues and mitigation strategies
- **Success Metrics**: Measurable goals for improvements

#### 3. Implementation
- **Configuration Updates**: Modernized configuration files
- **Script Optimization**: Performance-improved automation
- **Integration Fixes**: Resolved broken tool integrations
- **Documentation**: Updated setup and usage instructions

#### 4. Validation
- **Performance Benchmarks**: Before/after measurements
- **Integration Testing**: Verify all tools function correctly
- **User Experience**: Confirm workflow improvements
- **Maintenance Plan**: Strategy for ongoing optimization

### Quality Standards

#### Code Quality
- **Type Safety**: Use type systems to prevent runtime errors
- **Error Handling**: Explicit error handling, never ignore errors
- **Testing**: Comprehensive test coverage for critical paths
- **Performance**: Sub-second startup times for development tools
- **Security**: Validate inputs and use secure defaults

#### Documentation Quality
- **Decision Records**: Document architecture choices and rationale
- **Setup Instructions**: Clear, step-by-step installation guides
- **Troubleshooting**: Common issues and resolution steps
- **Maintenance**: Regular update and cleanup procedures

#### User Experience
- **Consistency**: Uniform command interfaces and behavior
- **Discoverability**: Clear help text and command completion
- **Feedback**: Progress indicators and error messages
- **Reliability**: Robust error handling and graceful degradation

### Success Criteria
- [ ] Shell startup time under 200ms
- [ ] All configured tools verified functional
- [ ] Zero ghost system files or configurations
- [ ] Comprehensive documentation and setup automation
- [ ] Measurable productivity improvements
- [ ] Clear maintenance and update procedures

Please analyze my current setup and provide a comprehensive modernization plan following these guidelines.
```

## Usage Instructions

### 1. Customization
- Replace bracketed placeholders with project-specific information
- Adjust architecture preferences based on project requirements
- Modify success criteria based on performance and functional goals
- Add or remove tool preferences based on user requirements

### 2. Execution
- Start with current state analysis before making changes
- Implement improvements incrementally with testing
- Document all changes and their rationale
- Measure performance impact of optimizations
- Validate all integrations after changes

### 3. Follow-up
- Schedule regular configuration health checks
- Update documentation as tools and preferences evolve
- Share learnings with team members or future projects
- Maintain upgrade path for major tool version changes

## Adaptation Guidelines

### For Different Technology Stacks
- **Python Projects**: Replace Go tools with equivalent Python ecosystem tools
- **JavaScript/Node**: Focus on npm/yarn optimization and build tooling
- **Rust Development**: Include cargo optimization and development tooling
- **DevOps Focus**: Emphasize container and deployment tooling

### For Different Environments
- **Team Environments**: Add collaboration tool preferences and shared configurations
- **Enterprise Settings**: Include security scanning and compliance requirements
- **Cloud-Native**: Focus on container and Kubernetes tooling integration
- **Windows Development**: Adapt file paths and tool equivalents for Windows

### For Different Experience Levels
- **Beginners**: Simplify architecture requirements and focus on essential tools
- **Advanced Users**: Include complex patterns like Event Sourcing and CQRS
- **Teams**: Add code review and collaboration workflow requirements
- **Enterprises**: Include security, compliance, and audit requirements

This prompt template provides a comprehensive framework for Claude configuration modernization while maintaining consistency with established architecture preferences and development practices.