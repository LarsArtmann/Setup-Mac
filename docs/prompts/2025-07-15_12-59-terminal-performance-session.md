# Reusable Prompts for Terminal Performance Optimization

Date: 2025-07-15T12:59:41+02:00  
Session: Terminal Performance & Fish Shell Migration

## 🚀 **Shell Performance Optimization Prompt**

### **Prompt Name:** "Ultimate Terminal Performance Optimization"

### **Use Case:** 
When terminal startup is slow (>500ms) and you want to achieve sub-100ms startup times while maintaining all functionality.

### **Prompt:**
```
You are a terminal performance optimization expert. I need to optimize my shell startup time from current slow performance to <100ms consistently.

CURRENT SITUATION:
- Current shell: [ZSH/Fish/Bash] 
- Startup time: [XXX]ms (measured with hyperfine)
- Performance budget: <500ms 95%tile, <250ms 50%tile
- Must maintain all current functionality and aliases

REQUIREMENTS:
1. Analyze current bottlenecks using profiling tools
2. Consider architectural changes (shell migration) vs optimization
3. Implement Fish + Carapace + Starship if beneficial
4. Create benchmarking scripts using hyperfine
5. Verify all functionality preserved
6. Document performance improvements

CONSTRAINTS:
- Must work on macOS with Nix configuration
- Preserve all development aliases and shortcuts
- Maintain beautiful prompt with git integration
- Keep completions for 1000+ commands
- No functionality regressions allowed

DELIVERABLES:
1. Performance analysis of current setup
2. Implementation plan with clear steps
3. Benchmarking methodology and results
4. Verification procedures for functionality
5. Documentation of all changes made

WORKFLOW:
- Create git commits after each logical change
- Test each component individually before integration
- Verify system state after each deployment
- Create rollback procedures for safety

Use hyperfine for accurate benchmarking and focus on customer value delivery.
```

## 🔧 **Nix Configuration Deployment Prompt**

### **Prompt Name:** "Safe Nix Darwin Configuration Deployment"

### **Use Case:** 
When deploying Nix darwin configurations and need to ensure complete, verified deployment without breaking the system.

### **Prompt:**
```
You are a Nix darwin configuration expert. I need to deploy configuration changes safely with complete verification.

CURRENT SITUATION:
- Configuration path: [/path/to/dotfiles/nix/]
- Target: [specific changes to be made]
- System: macOS with nix-darwin

REQUIREMENTS:
1. Analyze configuration for potential issues before deployment
2. Check for broken packages or dependency conflicts
3. Deploy using safe incremental approach
4. Verify system state after each change
5. Document all manual steps required

SAFETY PROCEDURES:
1. Always run `darwin-rebuild build` before `switch`
2. Check for broken packages (valgrind, etc.)
3. Commit configuration changes to git first
4. Create rollback procedures before deployment
5. Verify all packages are actually installed and working

VERIFICATION STEPS:
1. Check package availability in system PATH
2. Test all programs start correctly
3. Verify configuration files are properly generated
4. Test all aliases and shortcuts work
5. Confirm no functionality regressions

NEVER ASSUME:
- Timeout during deployment means success
- Configuration changes automatically work
- System activation happens without user interaction
- All packages will be available immediately

DELIVERABLES:
1. Pre-deployment configuration analysis
2. Step-by-step deployment procedure
3. Verification checklist with commands
4. Post-deployment system state report
5. Git commits for all changes

Focus on complete, verified deployment with no surprises.
```

## 📊 **Performance Monitoring Setup Prompt**

### **Prompt Name:** "Terminal Performance Regression Monitoring"

### **Use Case:** 
When you've achieved good performance and need to maintain it over time with automated monitoring.

### **Prompt:**
```
You are a performance monitoring expert. I need to set up automated monitoring for terminal performance to prevent regressions.

CURRENT SITUATION:
- Shell: [Fish/ZSH/Bash]
- Current performance: [XX]ms startup time
- Target: Maintain <100ms consistently
- Tools available: hyperfine, justfile, git

REQUIREMENTS:
1. Create automated performance benchmarking
2. Set up regression detection with thresholds
3. Integrate with existing development workflow
4. Store historical performance data
5. Alert on significant performance degradation

MONITORING STRATEGY:
1. Record performance metrics with each configuration change
2. Compare against historical baselines
3. Set reasonable regression thresholds (e.g., 20% degradation)
4. Create easy-to-read performance reports
5. Integrate with git workflow for tracking

IMPLEMENTATION:
1. Create justfile commands for performance recording
2. Set up automated benchmarking with hyperfine
3. Store performance data in structured format (JSON)
4. Create performance history analysis tools
5. Add performance checks to deployment workflow

DELIVERABLES:
1. Automated performance recording system
2. Regression detection with configurable thresholds
3. Historical performance tracking and reporting
4. Integration with existing development workflow
5. Documentation for maintaining performance monitoring

Focus on preventing performance regressions while maintaining development velocity.
```

## 🐛 **System Configuration Debugging Prompt**

### **Prompt Name:** "Shell Configuration Debugging & Troubleshooting"

### **Use Case:** 
When shell configuration isn't working as expected and you need systematic debugging.

### **Prompt:**
```
You are a shell configuration debugging expert. I need to systematically debug and fix shell configuration issues.

CURRENT PROBLEM:
- Shell: [Fish/ZSH/Bash]
- Issue: [specific problem description]
- Expected behavior: [what should happen]
- Actual behavior: [what is happening]

DEBUGGING APPROACH:
1. Isolate the problem to specific configuration areas
2. Test each component individually
3. Use debugging tools and verbose modes
4. Check system state and dependencies
5. Verify configuration file syntax and logic

SYSTEMATIC DEBUGGING:
1. Check if shell is properly set as default
2. Verify configuration files are being loaded
3. Test aliases and functions individually
4. Check environment variables and PATH
5. Verify prompt and completion systems

TOOLS TO USE:
- Shell debugging modes (set -x, fish --debug)
- Configuration validation commands
- System state inspection tools
- Performance profiling if relevant
- Git history to identify when issue started

DELIVERABLES:
1. Root cause analysis of the issue
2. Step-by-step debugging methodology used
3. Fix implementation with explanation
4. Prevention measures for similar issues
5. Documentation of debugging process

Focus on systematic problem-solving and preventive measures.
```

## 🏗️ **Architecture Migration Prompt**

### **Prompt Name:** "Terminal Architecture Migration Planning"

### **Use Case:** 
When considering major architectural changes to terminal setup (e.g., ZSH to Fish migration).

### **Prompt:**
```
You are a terminal architecture expert. I need to plan and execute a major terminal architecture migration.

CURRENT SITUATION:
- Current setup: [detailed description]
- Target architecture: [desired end state]
- Performance goals: [specific targets]
- Functionality requirements: [must-preserve features]

MIGRATION PLANNING:
1. Analyze current architecture strengths and weaknesses
2. Evaluate target architecture benefits and trade-offs
3. Create detailed migration plan with risk assessment
4. Plan testing and rollback procedures
5. Document all functionality that must be preserved

IMPLEMENTATION STRATEGY:
1. Create comprehensive functionality inventory
2. Set up parallel testing environment
3. Migrate configuration piece by piece
4. Verify each component works before proceeding
5. Create rollback procedures at each step

RISK MITIGATION:
1. Backup current working configuration
2. Test migration in safe environment first
3. Document all manual steps required
4. Create verification checklists
5. Plan for gradual rollout if needed

DELIVERABLES:
1. Current vs target architecture comparison
2. Detailed migration plan with timeline
3. Risk assessment and mitigation strategies
4. Testing procedures and success criteria
5. Complete documentation of the migration process

Focus on minimizing disruption while achieving architectural improvements.
```

These prompts can be reused for similar terminal optimization projects in the future.