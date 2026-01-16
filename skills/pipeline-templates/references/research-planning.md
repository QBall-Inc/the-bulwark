# Research & Planning Pipeline

## Purpose

Research and plan before implementation with iterative refinement.

## When to Use

- Complex features requiring deep research
- Architecture decisions
- Technology evaluations
- Pre-implementation planning
- Tasks where planning quality matters

## Pipeline Definition

```fsharp
// Research & Planning Pipeline
// Trigger: Complex task requiring planning
// Constraint: Minimum 3 iterations for quality
// Output: Reviewed and refined implementation plan

Researcher (gather information)                  // Haiku - lookups
|> PlanDrafter (create initial plan)             // Main thread (Orchestrator)
|> PlanReviewer (critical review)                // Sonnet - analysis
|> PlanRefiner (apply feedback)                  // Main thread (Orchestrator)
|> LOOP(min=3, max=5)                            // 3-5 iterations required
|> FinalValidator (ensure completeness)          // Sonnet - validation
```

## Stage Details

### Stage 1: Researcher

**Model**: Haiku (lookup task)

**GOAL**: Gather all information needed for planning.

**CONSTRAINTS**:
- Do NOT modify any files
- Focus on relevant information only
- Document sources and confidence

**CONTEXT**:
- Task/feature requirements
- Questions to answer
- Areas to research

**OUTPUT**: Research findings
```yaml
research:
  questions_answered:
    - question: "What authentication methods are supported?"
      answer: "OAuth 2.0, SAML, API keys"
      confidence: high
      source: "docs/auth.md"
    - question: "How is session state managed?"
      answer: "Redis-backed sessions"
      confidence: high
      source: "src/session/redis.ts"
  patterns_found:
    - pattern: "All API endpoints use middleware chain"
      location: "src/middleware/"
    - pattern: "Error handling via custom Error classes"
      location: "src/errors/"
  unknowns:
    - "Rate limiting configuration unclear"
    - "Caching strategy not documented"
```

### Stage 2: PlanDrafter

**Model**: Main thread (Orchestrator synthesizes)

**GOAL**: Create initial implementation plan from research.

**CONSTRAINTS**:
- Use research findings
- Follow project patterns
- Be specific and actionable

**CONTEXT**:
- Research findings from Stage 1
- Project structure
- Requirements/PRD

**OUTPUT**: Draft plan
```yaml
plan:
  version: 1
  objective: "Implement user authentication with OAuth 2.0"
  approach:
    - step: 1
      description: "Add OAuth provider configuration"
      files: ["src/config/oauth.ts"]
      effort: low
    - step: 2
      description: "Implement OAuth callback handler"
      files: ["src/auth/oauth-callback.ts"]
      effort: medium
    - step: 3
      description: "Add session creation on successful auth"
      files: ["src/session/create.ts"]
      effort: medium
  risks:
    - "Token refresh handling complexity"
  open_questions:
    - "Which OAuth providers to support initially?"
```

### Stage 3: PlanReviewer

**Model**: Sonnet (critical analysis)

**GOAL**: Critically review plan against requirements and context.

**CONSTRAINTS**:
- Do NOT modify any files
- Check against requirements
- Identify gaps and risks
- Be constructively critical

**CONTEXT**:
- Draft plan from Stage 2
- Original requirements
- Research findings
- Conversation context

**OUTPUT**: Review feedback
```yaml
review:
  iteration: 1
  overall: "Good start, needs refinement"
  gaps:
    - "Missing: Error handling for OAuth failures"
    - "Missing: Logout/token revocation flow"
  risks_identified:
    - risk: "Token storage security"
      recommendation: "Use encrypted storage, not plain Redis"
  suggestions:
    - "Add step for CSRF protection on callback"
    - "Consider adding refresh token rotation"
  questions:
    - "How will we handle users with multiple OAuth providers?"
```

### Stage 4: PlanRefiner

**Model**: Main thread (Orchestrator applies feedback)

**GOAL**: Incorporate review feedback into plan.

**CONSTRAINTS**:
- Address all gaps identified
- Respond to all questions
- Update risk mitigations

**CONTEXT**:
- Review feedback from Stage 3
- Previous plan version
- Research findings

**OUTPUT**: Refined plan (version N+1)

### Loop: Minimum 3 Iterations

**Why minimum 3?**
1. **Iteration 1**: Initial plan usually has gaps
2. **Iteration 2**: Addresses obvious issues, reveals deeper ones
3. **Iteration 3**: Refinement and polish

**Loop continues until**:
- Reviewer approves with no major gaps
- OR max iterations (5) reached

### Stage 5: FinalValidator

**Model**: Sonnet (validation)

**GOAL**: Final check that plan is complete and actionable.

**CONSTRAINTS**:
- Plan must be implementable
- All requirements covered
- Risks mitigated or accepted

**OUTPUT**: Validation result
```yaml
validation:
  approved: true
  final_plan_version: 3
  completeness_check:
    requirements_covered: true
    risks_documented: true
    steps_actionable: true
  ready_for_implementation: true
```

## Example Invocation

```markdown
## Pipeline: Research & Planning

### Stage 1: Researcher
Task: subagent_type=general-purpose, model=haiku
Prompt: [4-part prompt with research questions]

### Stage 2: PlanDrafter
Orchestrator synthesizes research into draft plan

### Stage 3: PlanReviewer (Iteration 1)
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reviews plan v1]

### Stage 4: PlanRefiner (Iteration 1)
Orchestrator applies feedback, creates plan v2

### Stage 3: PlanReviewer (Iteration 2)
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reviews plan v2]

[... continue for minimum 3 iterations ...]

### Stage 5: FinalValidator
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, validates final plan]
```

## Success Criteria

- Research gathered and documented
- Plan iterated minimum 3 times
- All gaps addressed
- Risks identified and mitigated
- Final validation passed

## Iteration Tracking

Track iterations explicitly:

```yaml
iterations:
  - version: 1
    reviewer_feedback: "Missing error handling"
    gaps_remaining: 3
  - version: 2
    reviewer_feedback: "Better, but security unclear"
    gaps_remaining: 1
  - version: 3
    reviewer_feedback: "Approved"
    gaps_remaining: 0
```

## Related Pipelines

- **New Feature**: For implementation after planning
- **Code Review**: For reviewing completed implementation
