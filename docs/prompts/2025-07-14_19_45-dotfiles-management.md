# Reusable Prompts for Dotfiles Management

## 1. Dotfiles Architecture Review

**Name**: `dotfiles-architecture-assessment`

**Prompt**:
```
Analyze this dotfiles repository for architecture and organization improvements:

ASSESSMENT AREAS:
1. **Package Management Strategy**:
   - Evaluate Nix vs Homebrew vs manual installations
   - Check for redundant or conflicting package sources
   - Assess reproducibility and maintenance burden

2. **Configuration Organization**:
   - Review file structure and logical grouping
   - Check for Home Manager vs manual configuration management
   - Evaluate environment variable and PATH management

3. **Automation Quality**:
   - Assess shell scripts for error handling and validation
   - Review task runner integration (justfile, makefiles)
   - Check for idempotent operations and proper logging

4. **Performance Impact**:
   - Measure shell startup times and identify bottlenecks
   - Evaluate caching strategies and lazy loading
   - Check for unnecessary operations in critical paths

FOCUS AREAS:
- Simplicity over complexity for personal use
- Measurable improvements in daily workflow
- Maintenance burden vs. feature benefits
- Clear documentation and troubleshooting

DELIVERABLES:
- Current state assessment with metrics
- Prioritized improvement recommendations
- Implementation complexity estimates
- Migration strategies for major changes

Remember: Dotfiles should enhance productivity, not showcase engineering patterns.
```

## 2. GitHub Issues Cleanup for Dotfiles

**Name**: `dotfiles-issue-management`

**Prompt**:
```
Review and clean up GitHub issues for this dotfiles repository:

ISSUE CATEGORIZATION:
1. **Close Immediately**:
   - Completed implementations with working solutions
   - Vague requests without clear success criteria
   - Duplicate issues or superseded by newer approaches

2. **Update with Progress**:
   - Partially implemented features needing documentation
   - Issues with working solutions but missing integration
   - Clear next steps for incomplete work

3. **Archive as Enhancement**:
   - Nice-to-have features without clear user benefit
   - Complex implementations with unclear maintenance burden
   - Experimental ideas that need validation

4. **Prioritize for Action**:
   - Broken functionality affecting daily workflow
   - Simple improvements with clear productivity benefits
   - Security or reliability issues

EVALUATION CRITERIA:
- Does this solve a real daily workflow problem?
- Is the maintenance burden reasonable for personal use?
- Can success be measured objectively?
- Is implementation complexity justified by benefits?

Focus on issues that improve the daily development experience rather than showcasing technical sophistication.
```

## 3. Complexity Appropriateness Assessment

**Name**: `complexity-justification-analysis`

**Prompt**:
```
Evaluate whether proposed technical solutions match the complexity of the actual problem:

COMPLEXITY ASSESSMENT FRAMEWORK:

**Problem Complexity Analysis**:
- How many users/use cases are affected?
- What is the frequency of the operation?
- What are the failure consequences?
- How often does the solution need to change?

**Solution Complexity Evaluation**:
- Implementation time and learning curve
- Maintenance burden and debugging difficulty
- Dependencies and external requirements
- Testing and validation requirements

**Appropriateness Matrix**:
- **Simple Problem + Simple Solution**: ✅ Ideal
- **Simple Problem + Complex Solution**: ❌ Over-engineering
- **Complex Problem + Simple Solution**: ⚠️ Verify sufficiency
- **Complex Problem + Complex Solution**: ✅ If justified

**Decision Criteria**:
1. **Personal Use**: Prefer simple, understandable solutions
2. **Team Use**: Consider shared knowledge and skills
3. **Production Use**: Justify complexity with reliability requirements
4. **Learning Goals**: Acknowledge when complexity is for education

**Red Flags**:
- Using enterprise patterns for personal tools
- Adding abstraction layers without clear benefits
- Implementing patterns because they're "best practice"
- Solving hypothetical future problems

Recommend simpler alternatives unless complexity is clearly justified by actual requirements.
```

## 4. Dotfiles Performance Optimization

**Name**: `dotfiles-performance-optimization`

**Prompt**:
```
Optimize dotfiles for shell startup performance and daily workflow efficiency:

PERFORMANCE MEASUREMENT:
1. **Baseline Establishment**:
   - Shell startup time with timing tools (hyperfine)
   - Command execution latency for common operations
   - Resource usage during normal operations
   - Rebuild/reload times for configuration changes

2. **Bottleneck Identification**:
   - Profile shell initialization scripts
   - Identify expensive operations in startup path
   - Check for synchronous operations that could be async
   - Analyze caching opportunities

OPTIMIZATION STRATEGIES:
1. **Lazy Loading**:
   - Defer completion loading until needed
   - Lazy initialize expensive tools and environments
   - Use async loading where possible

2. **Caching**:
   - Cache expensive computations
   - Pre-compile where applicable
   - Use appropriate cache invalidation strategies

3. **Path Optimization**:
   - Order PATH entries by frequency of use
   - Remove duplicate or non-existent paths
   - Minimize PATH length while maintaining functionality

4. **Tool Selection**:
   - Choose faster alternatives for common operations
   - Replace slow tools with modern equivalents
   - Remove unused tools and configurations

VALIDATION:
- Measure improvements with before/after metrics
- Test across different scenarios and machines
- Verify no functionality regression
- Document optimization techniques for future reference

Target: Noticeable daily workflow improvements with measurable performance gains.
```

## 5. Dotfiles Documentation Strategy

**Name**: `dotfiles-documentation-framework`

**Prompt**:
```
Create comprehensive documentation for a dotfiles repository:

DOCUMENTATION STRUCTURE:

1. **User-Focused Documentation**:
   - Quick start guide for new machine setup
   - Common tasks and workflows
   - Troubleshooting guide for frequent issues
   - Customization instructions for personal preferences

2. **Maintainer Documentation**:
   - Architecture decisions and rationale
   - Package management strategy and migration guides
   - Performance optimization techniques
   - Testing and validation procedures

3. **Reference Documentation**:
   - Complete tool inventory with purposes
   - Configuration file explanations
   - Environment variable documentation
   - Automation command reference

CONTENT PRIORITIES:
1. **Essential**: Setup instructions, common workflows, troubleshooting
2. **Helpful**: Customization guides, architecture explanations
3. **Reference**: Complete tool lists, detailed configurations

MAINTENANCE STRATEGY:
- Keep documentation close to code (README, inline comments)
- Automate documentation generation where possible
- Regular review and updates with configuration changes
- Examples and screenshots for complex procedures

QUALITY CRITERIA:
- New user can set up environment following documentation
- Common problems have clear solutions
- Configuration choices are explained with rationale
- Documentation stays current with actual implementation

Focus on practical utility over comprehensive coverage.
```

## 6. Tool Integration Validation

**Name**: `dotfiles-integration-testing`

**Prompt**:
```
Validate tool integration and identify configuration conflicts in dotfiles:

INTEGRATION TESTING FRAMEWORK:

1. **Tool Functionality Testing**:
   - Verify each installed tool works as expected
   - Check tool-specific configurations are applied
   - Test integration between related tools
   - Validate PATH and environment variable setup

2. **Configuration Conflict Detection**:
   - Check for duplicate environment variable definitions
   - Identify conflicting tool configurations
   - Verify configuration precedence is correct
   - Test configuration changes don't break other tools

3. **Workflow Validation**:
   - Test common development workflows end-to-end
   - Verify automation scripts work correctly
   - Check that all justfile/make commands function
   - Validate backup and restore procedures

4. **Cross-Platform Consistency**:
   - Test configuration on clean environment
   - Verify reproducibility across machines
   - Check for platform-specific issues
   - Validate migration procedures

VALIDATION CHECKLIST:
- [ ] All package managers (Nix, Homebrew) work correctly
- [ ] Shell environment loads without errors
- [ ] Development tools are properly configured
- [ ] Automation scripts complete successfully
- [ ] Performance meets established baselines
- [ ] Documentation accurately reflects current state

REPORTING:
- List any broken integrations found
- Document configuration conflicts and resolutions
- Provide recommendations for improving reliability
- Create test automation where beneficial

Goal: Ensure dotfiles provide reliable, consistent development environment.
```

## Usage Guidelines

### When to Use These Prompts
1. **dotfiles-architecture-assessment**: Annual review or major changes
2. **dotfiles-issue-management**: Monthly cleanup or after major releases
3. **complexity-justification-analysis**: Before implementing complex solutions
4. **dotfiles-performance-optimization**: When experiencing slowdowns
5. **dotfiles-documentation-framework**: When setting up new repository
6. **dotfiles-integration-testing**: After major configuration changes

### Customization Tips
- Adjust complexity thresholds based on personal vs. team use
- Modify performance targets based on hardware and preferences
- Adapt tool lists to specific development environments
- Scale documentation depth based on sharing requirements

### Success Metrics
- Faster daily workflows and reduced friction
- Reliable environment reproduction across machines
- Clear understanding of configuration choices
- Easier onboarding for new team members
- Reduced time spent on environment maintenance

These prompts prioritize practical daily utility over technical sophistication, matching the actual requirements of dotfiles management.