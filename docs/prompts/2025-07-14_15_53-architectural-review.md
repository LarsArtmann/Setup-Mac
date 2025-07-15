# Reusable Prompts for Architectural Review and Integration Projects

Date: 2025-07-14T15:53:37+02:00
Source Session: Comprehensive Architectural Review of better-claude-go Project

## Architectural Review Prompts

### 1. Comprehensive Architecture Analysis Prompt

```
Perform a comprehensive architectural review of [PROJECT_NAME] with the following analysis framework:

**Architecture Assessment:**
1. **Current State Analysis:**
   - Document existing architecture patterns and design decisions
   - Identify technical debt and architectural inconsistencies
   - Assess code quality, maintainability, and test coverage
   - Evaluate performance characteristics and bottlenecks

2. **Pattern Implementation Review:**
   - Analyze Domain-Driven Design (DDD) implementation if present
   - Review Event Sourcing and CQRS patterns for appropriateness
   - Assess library integration quality and consistency
   - Evaluate error handling and observability implementation

3. **Complexity Justification:**
   - Determine if architectural sophistication matches business requirements
   - Identify over-engineering risks and unnecessary complexity
   - Assess team capability alignment with chosen patterns
   - Evaluate maintenance burden vs. business value

4. **Integration Quality:**
   - Review library selection and integration patterns
   - Assess dependency management and version compatibility
   - Evaluate testing strategy comprehensiveness
   - Review documentation quality and completeness

**Deliverables Required:**
- Architecture assessment report with specific recommendations
- Library integration analysis with performance impact
- Testing framework evaluation and gap analysis
- Migration strategy for identified improvements

**Success Criteria:**
- Clear decision framework for architecture choices
- Quantified benefits and trade-offs of current patterns
- Practical improvement recommendations with implementation guidance
- Risk assessment for proposed changes

Focus on practical adoption criteria and real-world validation over theoretical perfection.
```

### 2. Library Integration Validation Prompt

```
Validate the integration and effectiveness of modern Go libraries in [PROJECT_NAME]:

**Library Assessment Framework:**
1. **Core Library Analysis:**
   - **Cobra CLI Framework:** Command structure, help generation, flag management, user experience
   - **Viper Configuration:** Multi-source config, type safety, environment integration, discovery
   - **Samber/lo Functional:** Type safety, performance, code clarity, memory efficiency
   - **OpenTelemetry:** Observability, tracing, metrics, production readiness

2. **Integration Quality Metrics:**
   - Type safety improvements and compile-time error prevention
   - Performance impact measurement (startup time, memory usage, binary size)
   - Code maintainability and readability improvements
   - Developer experience and productivity gains

3. **Best Practice Validation:**
   - Interface abstraction around external libraries
   - Dependency injection patterns without frameworks
   - Configuration management centralization
   - Testing strategy for library integrations

4. **Anti-Pattern Detection:**
   - Over-dependency on external libraries
   - Inappropriate library usage patterns
   - Performance bottlenecks from library overhead
   - Maintenance risks from library complexity

**Validation Approach:**
- Create minimal examples demonstrating each integration
- Measure performance before/after integration
- Document configuration patterns and best practices
- Provide rollback strategies for problematic integrations

**Output Requirements:**
- Library integration report with performance metrics
- Best practice documentation for each library
- Configuration templates for consistent usage
- Migration guides for adoption or removal
```

### 3. DDD and Event Sourcing Appropriateness Assessment

```
Assess the appropriateness of Domain-Driven Design and Event Sourcing patterns for [PROJECT_NAME]:

**Pattern Suitability Analysis:**
1. **Business Complexity Assessment:**
   - Identify genuine business rules and invariants
   - Evaluate domain complexity vs. CRUD operations
   - Assess audit and compliance requirements
   - Determine state change frequency and importance

2. **Team and Project Context:**
   - Evaluate team expertise with DDD patterns
   - Assess project timeline and complexity budget
   - Determine long-term maintenance considerations
   - Analyze collaboration and communication needs

3. **Technical Benefit Analysis:**
   - Quantify benefits of event sourcing for the specific use case
   - Assess CQRS value for read/write separation needs
   - Evaluate aggregate design appropriateness
   - Measure actual vs. theoretical performance impact

4. **Complexity Cost Evaluation:**
   - Infrastructure overhead (event store, message bus)
   - Development velocity impact (initial and ongoing)
   - Debugging and troubleshooting complexity
   - Testing strategy complexity

**Decision Framework:**
Apply sophisticated patterns when:
- Complex business rules require enforcement
- Complete audit trail is business-critical
- Large team needs clear domain boundaries
- System expected to evolve significantly

Avoid sophisticated patterns when:
- Simple CRUD operations dominate
- Small team with limited DDD expertise
- Performance is critical and patterns add overhead
- Short-term project with limited evolution expected

**Deliverables:**
- Pattern appropriateness assessment with clear recommendation
- Simplified alternative architecture if patterns inappropriate
- Migration strategy if patterns should be removed
- Implementation guidelines if patterns are appropriate
```

### 4. Testing Framework Comprehensive Review

```
Evaluate and enhance the testing framework for [PROJECT_NAME] across multiple dimensions:

**Testing Architecture Assessment:**
1. **Framework Integration Review:**
   - **BDD Testing (Godog):** Feature file quality, step definition reuse, scenario coverage
   - **Unit Testing (Testify):** Test organization, mock usage, assertion quality
   - **Security Testing:** Input validation, injection prevention, access control
   - **Integration Testing:** End-to-end workflows, external dependency handling

2. **Test Quality Metrics:**
   - Coverage analysis across layers (unit, integration, end-to-end)
   - Test maintainability and brittleness assessment
   - Performance testing for critical paths
   - Security vulnerability coverage

3. **Testing Best Practices Validation:**
   - Builder pattern usage for test data creation
   - Mock object design and dependency isolation
   - Table-driven test implementation
   - Test fixture management and cleanup

4. **Framework Selection Justification:**
   - Library choice rationale (testify, godog, custom frameworks)
   - Integration complexity vs. testing value
   - Maintenance overhead assessment
   - Developer experience with testing tools

**Enhancement Opportunities:**
- Identify gaps in test coverage (functional, performance, security)
- Recommend additional testing tools or patterns
- Propose test automation improvements
- Suggest testing documentation enhancements

**Validation Approach:**
- Execute full test suite and analyze results
- Measure test execution time and resource usage
- Review test failure analysis and debugging capabilities
- Assess test maintenance burden over time

**Output Requirements:**
- Testing framework assessment with improvement recommendations
- Test coverage report with gap analysis
- Testing best practice documentation
- Tool selection guidelines for future projects
```

### 5. Performance Optimization and Validation

```
Conduct comprehensive performance analysis and optimization for [PROJECT_NAME]:

**Performance Assessment Framework:**
1. **Baseline Measurement:**
   - Application startup time and resource usage
   - Memory allocation patterns and garbage collection impact
   - Binary size and deployment characteristics
   - Network and I/O operation efficiency

2. **Comparative Analysis:**
   - Shell script vs. Go binary performance comparison
   - Simple vs. sophisticated architecture performance trade-offs
   - Library integration performance impact
   - Configuration loading and caching efficiency

3. **Optimization Techniques Evaluation:**
   - Lazy loading implementation and effectiveness
   - Caching strategy appropriateness and hit rates
   - Functional programming performance characteristics
   - Concurrency pattern efficiency

4. **Bottleneck Identification:**
   - Profile application execution with appropriate tools
   - Identify CPU, memory, and I/O bottlenecks
   - Analyze dependency contribution to performance issues
   - Assess architectural pattern performance impact

**Optimization Strategies:**
- Implement performance monitoring and alerting
- Create performance regression test suite
- Document optimization techniques and trade-offs
- Establish performance benchmarks for future changes

**Measurement Approach:**
- Use benchmarking tools (hyperfine, Go benchmarks)
- Implement application performance monitoring
- Create synthetic load testing scenarios
- Monitor real-world usage patterns

**Deliverables:**
- Performance analysis report with specific metrics
- Optimization implementation plan with priorities
- Performance monitoring setup guide
- Regression prevention strategy
```

### 6. GitHub Issues Management and Technical Debt

```
Systematically address GitHub issues and technical debt for [PROJECT_NAME]:

**Issue Assessment Framework:**
1. **Issue Quality Analysis:**
   - Triage criteria development (clear description, acceptance criteria)
   - Implementation readiness assessment
   - Scope definition and task breakdown
   - Priority matrix based on effort vs. impact

2. **Technical Debt Identification:**
   - Code quality metrics and static analysis
   - Architecture inconsistency detection
   - Performance debt assessment
   - Documentation gaps and maintenance burden

3. **Resolution Strategy Development:**
   - Quick wins identification for momentum building
   - Batch processing approach for related issues
   - Long-term technical debt resolution planning
   - Automation opportunity identification

4. **Impact Assessment:**
   - Productivity impact measurement
   - Reliability and stability risk analysis
   - User experience degradation assessment
   - Maintenance cost evaluation

**Management Approach:**
- Implement issue labeling and categorization system
- Create automated issue quality validation
- Establish regular technical debt review process
- Link issues to implementation commits and documentation

**Tracking and Communication:**
- Regular progress updates and status communication
- Integration with development workflow
- Documentation of resolution patterns
- Success metrics and improvement measurement

**Output Requirements:**
- Issue management strategy with clear processes
- Technical debt assessment report with priorities
- Resolution implementation plan with timelines
- Automation tools for issue management efficiency
```

### 7. Architecture Decision Documentation

```
Create comprehensive architecture decision records (ADRs) for [PROJECT_NAME]:

**ADR Documentation Framework:**
1. **Decision Context Capture:**
   - Business requirements and constraints
   - Technical requirements and limitations
   - Team capabilities and preferences
   - Timeline and resource constraints

2. **Alternative Analysis:**
   - Options considered with pros/cons analysis
   - Trade-off evaluation (performance, complexity, maintainability)
   - Risk assessment for each alternative
   - Implementation effort estimation

3. **Decision Rationale:**
   - Clear explanation of chosen approach
   - Benefits expected and risks accepted
   - Success criteria and measurement approach
   - Rollback strategy if decision proves incorrect

4. **Implementation Guidance:**
   - Specific implementation patterns and examples
   - Integration guidelines and best practices
   - Testing strategy for the decision
   - Documentation and maintenance requirements

**ADR Categories:**
- Library selection and integration decisions
- Architectural pattern adoption (DDD, Event Sourcing, CQRS)
- Performance optimization approaches
- Testing strategy and framework choices
- Security implementation decisions

**Template Structure:**
- Title: Brief description of the decision
- Status: Proposed, Accepted, Superseded
- Context: What is the issue that motivates this decision?
- Decision: What is the change that we're proposing or have agreed to?
- Consequences: What becomes easier or more difficult to do because of this change?

**Maintenance Process:**
- Regular review of existing ADRs for relevance
- Update process when decisions are superseded
- Integration with code review and development workflow
- Knowledge sharing and onboarding integration
```

## Usage Guidelines for Prompts

### 1. Prompt Customization Instructions:
- Replace [PROJECT_NAME] with actual project name
- Adjust assessment frameworks based on project complexity
- Modify success criteria based on business requirements
- Adapt deliverables to match project phase and needs

### 2. Implementation Sequence:
1. Start with comprehensive architecture analysis
2. Follow with library integration validation
3. Assess sophisticated patterns (DDD, Event Sourcing) appropriateness
4. Review testing framework comprehensiveness
5. Conduct performance optimization analysis
6. Address GitHub issues and technical debt
7. Document all decisions with ADRs

### 3. Quality Assurance:
- Validate all assessments with quantitative metrics
- Include practical examples and implementation guidance
- Provide clear recommendations with rationale
- Create actionable improvement plans with priorities

### 4. Success Metrics:
- Measurable improvements in code quality
- Reduced complexity where appropriate
- Enhanced performance characteristics
- Improved developer productivity
- Better documentation and knowledge sharing

These prompts provide a comprehensive framework for architectural review and improvement projects, ensuring systematic analysis and practical outcomes while avoiding over-engineering and unnecessary complexity.