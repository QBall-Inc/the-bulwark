# Code-Review Skill Synthesis

*Session 30 - T-001 Brainstorming Output*
*Date: 2026-01-30*

---

## Executive Summary

Five research sub-agents (Direct, Role-Based Expert, Contrarian, First Principles, Historical) analyzed 13+ external code review skills and all local Bulwark architecture docs. This synthesis captures the **unanimous consensus** on core architecture and **aligned decisions** on execution strategy.

---

## 1. Unanimous Consensus (All 5 Approaches Agree)

### 1.1 Four-Section Structure

All approaches validate the planned 4-section architecture:

| Section | Purpose | Boundary |
|---------|---------|----------|
| **Security** | OWASP patterns, injection, auth/authz | Threats & exploits |
| **Type Safety** | `any` detection, null handling, unsafe assertions | Type system holes |
| **Linting** | Complexity judgment, semantic naming | Style requiring judgment |
| **Coding Standards** | Pattern adherence, documentation quality | Conventions & architecture |

### 1.2 Two-Phase Review (Critical Insight)

**Unanimous**: Run deterministic tools BEFORE LLM judgment.

```
Phase 1: Static Analysis (Deterministic)
├── Run: just typecheck → capture output
├── Run: just lint → capture output
└── If failures: STOP, return to user (fail fast)

Phase 2: LLM Review (Judgment-Based)
└── Analyze code + static output for patterns tools cannot catch
```

**Why**: Saves tokens, eliminates false positives from LLM rediscovering what static tools already caught.

### 1.3 Severity Tiering

All approaches recommend 3-tier severity:

| Tier | Label | Criteria | Action |
|------|-------|----------|--------|
| :red_circle: | **CRITICAL** | Security vulnerabilities, type safety holes causing runtime errors | Must fix before merge |
| :yellow_circle: | **IMPORTANT** | Anti-patterns, missing tests, significant quality issues | Should fix |
| :green_circle: | **SUGGESTION** | Style improvements, naming clarity, minor refactoring | Optional |

### 1.4 Externalized Review

**Unanimous**: Code review must run in isolated context to prevent self-review bias.
- `bulwark-code-auditor` (P4.3) uses `context: fork`
- Never reviews code it generated

### 1.5 Actionable Feedback Format

Every finding must include:

```yaml
- file: src/auth/token.ts
  line: 45
  severity: critical
  confidence: verified
  pattern: "SQL injection"
  description: "User input concatenated into SQL query"
  why: "Allows attacker to execute arbitrary SQL commands"
  fix: "Use parameterized query: db.query('SELECT * FROM users WHERE id = ?', [userId])"
```

---

## 2. Key Insights by Approach

### 2.1 Direct Approach

- **Role-based agent pattern**: Same skill, different sections per pipeline stage
- **Two invocation modes**: (1) Direct user call runs ALL sections, (2) Pipeline stages reference ONE section
- **Anti-pattern vs recommended**: Side-by-side examples teach "why" not just "what"

### 2.2 Expert (Role-Based)

- **Review depth scaling**: Not all changes need full review
  - `<50 lines`: Security only (quick critical scan)
  - `50-500 lines`: Security + Type Safety
  - `>500 lines`: All sections
- **Static-first workflow**: LLM explains/triages static analysis output, doesn't rediscover it
- **False positive prevention**: Include "What to Skip" guidance for common false alarms

### 2.3 Contrarian

- **Inverted execution order is industry-wide problem**: Most tools waste tokens on code that won't compile
- **No false positive measurement**: Tools optimize for recall (finding issues) not precision (minimizing noise)
- **Missing AI-specific patterns**:
  - Copy-paste modification detection (common AI generation flaw)
  - Cross-file structural similarity analysis
  - Git history context for change justification
- **Framework-specific security**: React XSS ≠ Django XSS ≠ Express XSS

### 2.4 First Principles

- **Core truth**: If a check can be automated, it MUST be automated and EXCLUDED from manual review
- **Excluded as unnecessary complexity**:
  - Performance review (requires profiling, not inspection)
  - Architecture review (belongs in design phase)
  - Plan alignment (requirements validation, not code review)
  - Style enforcement (100% automatable)
- **Test quality → test-audit**: Don't reinvent T0-T4 classification in code-review

### 2.5 Historical

- **50 years of evidence**: Fagan inspections (1976) → Static analysis → IDE integration → AI era
- **Recurring successes**: Structure/checklists, severity tiers, externalized review, deterministic pre-filtering
- **Recurring failures**: False positive plague, style bikeshedding, self-review bias, synchronous bottlenecks
- **AI era insight**: AI amplifies human judgment but cannot replace externalized review

---

## 3. Aligned Decisions

The following decisions were aligned between the orchestrator and user during T-001 brainstorming.

### 3.1 Review Depth Scaling

**Decision**: Default to comprehensive review; offer `--quick` flag for user-invocable speed.

**Rationale**: Most invocations occur via pipelines triggered by PostToolUse hooks, which should be thorough quality gates. Users who want speed can explicitly opt-in to quick mode.

| Mode | Trigger | Sections Run |
|------|---------|--------------|
| **Comprehensive** (default) | Pipeline invocation, direct invocation without flags | All 4 sections |
| **Quick** (`--quick` flag) | User opts for speed | Tiered by lines changed |

**Quick Mode Thresholds** (when `--quick` specified):

| Lines Changed | Sections |
|---------------|----------|
| <50 lines | Security only |
| 50-500 lines | Security + Type Safety |
| >500 lines | All sections |

### 3.2 Framework Detection

**Decision**: Auto-detect framework from `package.json` with fallback; offer `--framework` override for user-invocable.

**Rationale**: Pipelines run automatically and need framework context without user intervention. Detection from `package.json` is straightforward and low-risk.

**Detection Logic**:

```
package.json dependencies → Framework
─────────────────────────────────────
react, next, gatsby       → React
express, fastify, koa     → Express/Node
@angular/*                → Angular
vue, nuxt                 → Vue
(none of above)           → Generic (OWASP only)

requirements.txt/pyproject.toml:
django                    → Django
flask                     → Flask
fastapi                   → FastAPI
(none of above)           → Generic Python
```

**User Override**: `--framework=react|express|django|generic`

**Fallback Behavior**: If detection is ambiguous or fails, use Generic patterns (OWASP Top 10 only) and note in output that framework-specific checks were skipped.

### 3.3 Confidence Scores

**Decision**: Use 2-tier confidence model (Verified vs Suspected) with evidence field.

| Level | Label | Criteria | Example |
|-------|-------|----------|---------|
| **Verified** | :lock: | Data flow traced, exploit path confirmed | "User input from `req.query.id` flows to `db.query()` at line 45 without sanitization" |
| **Suspected** | :warning: | Pattern matches but context unclear | "String concatenation in SQL-like context - verify if this is actually a query" |

**Output Format**:

```yaml
- severity: critical
  confidence: verified
  evidence: "User input from req.query.id flows to db.query() at line 45"

- severity: important
  confidence: suspected
  evidence: "Pattern matches SQL concatenation - manual verification recommended"
```

### 3.4 Git Context

**Decision**: Optional and targeted - include only for complexity findings, controlled by flag.

**When to Include**:
- Complex/unusual code flagged by Linting section
- Intentional violations (e.g., `// eslint-disable` comments)
- NOT for obvious issues (SQL injection doesn't need history)

**Output Format** (when enabled):

```yaml
- severity: important
  section: linting
  pattern: deep_nesting
  description: "5 levels of nesting in processOrder()"
  git_context:
    last_modified: "2025-08-15 by @alice"
    commit_message: "Workaround for #1234 - external API timeout handling"
    note: "Complexity may be intentional workaround - verify before refactoring"
```

**Configuration**: `--include-git-context` flag (default: false)

---

## 4. Skill Structure

### 4.1 Directory Layout

**IMPORTANT**: Templates, examples, framework patterns, and reference content MUST be in subfolders, NOT embedded in SKILL.md. The SKILL.md contains instructions and references to these files.

```
skills/code-review/
├── SKILL.md                          # Core instructions, section definitions
├── references/
│   ├── security-patterns.md          # OWASP patterns, injection examples
│   ├── type-safety-patterns.md       # any/null/assertion patterns
│   ├── linting-patterns.md           # Complexity, naming patterns
│   └── standards-patterns.md         # Atomic principles, documentation
├── examples/
│   ├── anti-patterns/                # BAD code examples
│   │   ├── security.ts
│   │   ├── type-safety.ts
│   │   ├── linting.ts
│   │   └── standards.ts
│   └── recommended/                  # GOOD code examples
│       ├── security.ts
│       ├── type-safety.ts
│       ├── linting.ts
│       └── standards.ts
├── frameworks/
│   ├── react.md                      # React-specific patterns
│   ├── express.md                    # Express/Node patterns
│   ├── angular.md                    # Angular patterns
│   ├── vue.md                        # Vue patterns
│   ├── django.md                     # Django patterns
│   ├── flask.md                      # Flask patterns
│   └── generic.md                    # Fallback OWASP-only
└── templates/
    ├── output-direct.yaml            # Output template for direct invocation
    └── output-pipeline.yaml          # Output template for pipeline stage
```

### 4.2 Frontmatter

```yaml
---
name: code-review
description: >
  Unified code review skill with sections for Security, Type Safety, Linting,
  and Coding Standards. Each section independently referenceable by role-based
  pipeline agents. Auto-detects framework from package.json.
user-invocable: true
agent: sonnet
skills:
  - subagent-prompting
  - subagent-output-templating
---
```

### 4.3 Section Structure (H2 Headers in SKILL.md)

Each section in SKILL.md should:
1. Define its **Purpose** and **Boundary**
2. List **Prerequisites** (static checks that must pass first)
3. Reference the **patterns file** in `references/`
4. Reference the **examples** in `examples/`
5. Specify **Output Format** requirements
6. Include **What to Skip** guidance for false positives

Example structure:

```markdown
## Security

### Purpose
Identify security vulnerabilities that static analysis cannot catch.

### Boundary
This section covers threats and exploits. Authentication/authorization logic,
injection patterns, secrets exposure. Does NOT cover type errors (→ Type Safety)
or code style (→ Linting).

### Prerequisites
- `just typecheck` passed
- `just lint` passed

### Patterns
See `references/security-patterns.md` for:
- OWASP Top 10 checklist with detection criteria
- Framework-specific patterns (load from `frameworks/{detected}.md`)

### Examples
- Anti-patterns: `examples/anti-patterns/security.ts`
- Recommended: `examples/recommended/security.ts`

### What to Skip (Common False Positives)
- Parameterized queries flagged due to nearby string concatenation
- Test fixtures with intentional "vulnerable" code for testing
- Comments containing SQL examples

### Output Format
Use template from `templates/output-pipeline.yaml` with:
- confidence: verified | suspected
- evidence: Data flow trace or pattern match description
- owasp: Category reference (e.g., A03:2021)
```

---

## 5. Output Templates

### 5.1 Direct Invocation (`/code-review`)

```yaml
code_review:
  timestamp: 2026-01-30T00:00:00Z
  mode: comprehensive  # or "quick"
  framework_detected: react
  files_reviewed:
    - src/auth/token.ts
    - src/api/users.ts

  static_analysis:
    typecheck: passed
    lint: passed

  findings:
    critical:
      - file: src/auth/token.ts
        line: 45
        section: security
        pattern: sql_injection
        confidence: verified
        evidence: "User input from req.query.id flows to db.query()"
        description: "User input concatenated into SQL query"
        why: "Allows arbitrary SQL execution"
        fix: "Use parameterized query"

    important:
      - file: src/api/users.ts
        line: 120
        section: type_safety
        pattern: any_usage
        confidence: verified
        evidence: "Explicit 'any' type annotation at line 120"
        description: "API response typed as 'any'"
        why: "Bypasses type checking for response handling"
        fix: "Define interface UserResponse and use typed fetch"

    suggestions:
      - file: src/api/users.ts
        line: 85
        section: linting
        pattern: naming
        confidence: suspected
        evidence: "Generic name pattern detected"
        description: "Variable 'data' could be more descriptive"
        why: "Generic name doesn't reveal purpose"
        fix: "Rename to 'userProfile' or 'apiResponse'"

  summary:
    critical_count: 1
    important_count: 1
    suggestion_count: 1
    recommendation: "Fix critical SQL injection before merge"
```

### 5.2 Pipeline Stage (SecurityReviewer)

```yaml
security_review:
  timestamp: 2026-01-30T00:00:00Z
  section: security
  framework: react
  files_reviewed:
    - src/auth/token.ts

  findings:
    - severity: critical
      confidence: verified
      file: src/auth/token.ts
      line: 45
      pattern: sql_injection
      owasp: A03:2021
      evidence: "User input from req.query.id flows to db.query() at line 45"
      description: "User input concatenated into SQL query"
      fix: "db.query('SELECT * FROM users WHERE id = ?', [userId])"

  summary: "1 critical security vulnerability found: SQL injection"
```

---

## 6. Integration with Bulwark Architecture

### 6.1 Defense-in-Depth Position

```
Outer Ring (Hooks)
├── PostToolUse: enforce-quality.sh
│   └── Runs `just typecheck` + `just lint` BEFORE code-review
│   └── Blocks on failures (exit 2)

Inner Ring (Skills)
├── code-review skill (this)
│   └── Four sections, role-based referencing
│   └── Assumes static checks passed
│   └── Auto-detects framework

Middle Ring (Agents)
├── bulwark-code-auditor (P4.3)
│   └── context: fork (isolated)
│   └── Runs all sections
│   └── Never fixes, only identifies
```

### 6.2 Pipeline Integration

```fsharp
// Code Review Pipeline (from pipeline-templates)
SecurityReviewer (Security section)
|> TypeSafetyReviewer (Type Safety section)
|> LintReviewer (Linting section)
|> StandardsReviewer (Coding Standards section)
|> ReviewSynthesizer (consolidate findings)
|> (if findings.critical > 0 then IssueDebugger else Done)

// Fix Validation Pipeline
IssueAnalyzer (root cause)
|> Implementer (apply fix)
|> CodeAuditor (all sections - verify fix quality)  // Uses this skill
|> TestAuditor (verify tests)
|> (if issues > 0 then loop else Done)
```

### 6.3 Invocation Modes

| Mode | Sections Run | Triggered By |
|------|--------------|--------------|
| Direct (`/code-review`) | All 4 (comprehensive) | User invocation |
| Direct (`/code-review --quick`) | Tiered by lines | User opts for speed |
| Pipeline stage | 1 specific | Role-based agent with section reference |
| Standalone audit | All 4 | `bulwark-code-auditor` agent |

---

## 7. References Used

### External Skills Analyzed

| Source | Key Contribution |
|--------|------------------|
| [fredflint gist](https://gist.github.com/fredflint/932c91d13cf1ee8db022061f671ce546) | Linus Torvalds framework, data structures first |
| [skillcreatorai](https://skills.sh/skillcreatorai/ai-agent-skills/code-review) | Severity tiers with emoji, anti-pattern examples |
| [superpowers code-reviewer](https://github.com/obra/superpowers/blob/main/agents/code-reviewer.md) | Plan alignment, constructive feedback |
| [dify frontend-code-review](https://skills.sh/langgenius/dify/frontend-code-review) | React-specific patterns, dual review modes |
| [code-review-excellence](https://skills.sh/wshobson/agents/code-review-excellence) | Question-based feedback, severity labels |
| [gemini code-reviewer](https://skills.sh/google-gemini/gemini-cli/code-reviewer) | 7 analytical pillars, structured output |
| [ordinary-claude-skills](https://github.com/Microck/ordinary-claude-skills/tree/main/skills_categorized/code-quality) | Multi-agent parallel review, scoring framework |

### Historical Sources

| Era | Source | Lesson |
|-----|--------|--------|
| 1970s | Fagan Inspections | Structure/checklists work, but cost matters |
| 1990s-2000s | Coverity, FindBugs | False positive plague kills adoption |
| 2010s | ESLint, SonarQube | Severity tiers + IDE integration = success |
| 2020s | Claude Code, Copilot | AI amplifies judgment but needs externalized review |

### Research Agent Logs

| Approach | Log File |
|----------|----------|
| Direct | `logs/research-direct-approach-20260130.yaml` |
| Role-Based Expert | `logs/research-role-based-approach-20260130.yaml` |
| Contrarian | `logs/research-contrarian-approach-20260130.yaml` |
| First Principles | `logs/research-first-principles-approach-20260130.yaml` |
| Historical | `logs/research-historical-approach-20260130.yaml` |

---

## 8. Implementation Notes

### 8.1 File Organization Requirement

**CRITICAL**: When implementing the skill, all supporting content MUST be in subfolders:

- **SKILL.md** contains ONLY:
  - Frontmatter
  - Section definitions with purpose/boundary
  - References to pattern files
  - Output format requirements
  - Invocation instructions

- **Subfolders** contain:
  - `references/` - Detailed patterns and checklists
  - `examples/` - Code examples (anti-patterns and recommended)
  - `frameworks/` - Framework-specific pattern libraries
  - `templates/` - Output format templates

This separation ensures:
1. SKILL.md remains readable and maintainable
2. Patterns can be updated independently
3. Framework support can be extended without modifying core skill
4. Examples serve as test fixtures for validation

### 8.2 Framework Detection Implementation

```typescript
// Pseudo-code for framework detection
function detectFramework(projectPath: string): Framework {
  const pkg = readPackageJson(projectPath);
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };

  if (deps['react'] || deps['next'] || deps['gatsby']) return 'react';
  if (deps['express'] || deps['fastify'] || deps['koa']) return 'express';
  if (deps['@angular/core']) return 'angular';
  if (deps['vue'] || deps['nuxt']) return 'vue';

  // Check Python
  const pyDeps = readRequirementsTxt(projectPath) || readPyprojectToml(projectPath);
  if (pyDeps?.includes('django')) return 'django';
  if (pyDeps?.includes('flask')) return 'flask';
  if (pyDeps?.includes('fastapi')) return 'fastapi';

  return 'generic'; // Fallback
}
```

### 8.3 Quick Mode Implementation

```typescript
// Pseudo-code for quick mode section selection
function selectSections(linesChanged: number, quickMode: boolean): Section[] {
  if (!quickMode) {
    return ['security', 'type_safety', 'linting', 'standards']; // All sections
  }

  if (linesChanged < 50) {
    return ['security'];
  } else if (linesChanged < 500) {
    return ['security', 'type_safety'];
  } else {
    return ['security', 'type_safety', 'linting', 'standards'];
  }
}
```

---

*This synthesis document serves as the specification for P4.1 code-review skill implementation.*
