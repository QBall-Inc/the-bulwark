# Bug-Magnet-Data Skill Synthesis

*Session 30 - P4.2 Brainstorming Output*
*Date: 2026-01-30*

---

## Executive Summary

Five research sub-agents (Direct, Expert, Contrarian, First Principles, Historical) analyzed edge case testing patterns spanning 50+ years of history. This synthesis captures the **unanimous consensus** on curated, boundary-focused data over generated noise, with **aligned decisions** on structure, inclusions, and update strategy.

---

## 1. Unanimous Consensus (All 5 Approaches Agree)

### 1.1 Boundaries Are Where Bugs Hide

From 1970s BVA through modern fuzzing: testing boundaries finds more bugs than testing middle values.

**Pattern**: Test `min-1, min, min+1, max-1, max, max+1` - not random values in between.

### 1.2 Curation Beats Generation

| Approach | Evidence |
|----------|----------|
| Historical | BugMagnet.org's 50 strings find more bugs than 10,000 random inputs |
| Expert | Tier 1 (boundary + null + injection) catches 80% of bugs |
| Contrarian | Meta's LLM generates 1:20 ratio of working tests |
| First Principles | Minimal essential set derived from 8 bug causation classes |

**Implication**: bug-magnet-data should be **pre-curated reference data**, NOT runtime LLM generation.

### 1.3 Organize by Problem Domain, Not Tool

All approaches agree: organize by data type (strings, numbers, dates), not by language/framework.

| Good | Bad |
|------|-----|
| `strings/unicode.yaml` | `javascript/edge-cases.yaml` |
| `numbers/boundaries.yaml` | `python/numeric-tests.yaml` |

### 1.4 Context-Dependent Application

Not every edge case applies everywhere. SQL injection is irrelevant to CLI tools. Unicode is irrelevant to ASCII-only systems.

**Requirement**: Include "When to Use" guards for each category in main SKILL.md.

### 1.5 Small, Fast, Zero-Config

- **Small**: ~50-100 values per category, not thousands
- **Fast**: Lookup, not generation
- **Zero-config**: Just reference the skill

---

## 2. Key Insights by Approach

### 2.1 Direct Approach

- 19 comprehensive categories from BugMagnet covering primitives → domain-specific → collections → behavioral
- Boundary±1 testing pattern with concrete examples
- Three consumers: test-audit (Step 7), bulwark-verify (script injection), fix-validator (boundary testing)

### 2.2 Expert (Role-Based)

- **Tier 1 (Essential - 80% of bugs)**: Boundary values, Empty/null, Basic injection, Length extremes
- **Tier 2 (Important - 15%)**: Unicode, Numeric edge cases, Advanced injection
- **Tier 3 (Optional - 5%)**: Date/time, Concurrent/stateful, Destructive patterns
- Mark destructive patterns (DROP TABLE) as **manual-only**
- Reference external maintained lists (Big List of Naughty Strings, OWASP Fuzz Vectors)

### 2.3 Contrarian

**8 Overlooked Categories**:
1. State machine edge cases (interrupted flows, invalid transitions)
2. Concurrency/race conditions (multi-user conflicts)
3. Time-based edge cases (DST transitions, leap years)
4. Boundary mutation patterns (>= vs >, inclusive vs exclusive)
5. Integration chain failures (type mismatches between chained functions)
6. Context-specific domain patterns (financial regs, legacy constraints)
7. Resource exhaustion under load (memory leaks at scale)
8. Partial failure/resilience (network timeouts, partial responses)

**8 Overrated Patterns** (create noise, rarely catch bugs):
1. 100+ SQL injection patterns (93% of codebases use ORMs)
2. XSS in non-HTML contexts (JSON APIs don't render HTML)
3. Unicode on ASCII-only systems
4. 50+ boundary values (business boundaries > language limits)
5. Every HTTP status code (services return 6-10, not 50+)
6. Null testing on required fields (input validation catches this)
7. Timezone testing on UTC-only systems
8. 100+ mutation operators (trivial mutations waste effort)

### 2.4 First Principles

**8 Bug Causation Classes** (derived from Stanford research):
1. Boundary violations (largest error class)
2. Type mismatches and coercion
3. Encoding and normalization issues
4. Precision and overflow errors
5. State corruption and invalid transitions
6. Special value handling failures
7. Length and resource exhaustion
8. Time and temporal logic errors

**Minimal Essential Categories**: Strings, Numbers, Boolean/null, Collections, Dates, State transitions, Encoding, Input formats

### 2.5 Historical

- **1970s BVA**: Boundaries still where bugs hide after 50 years
- **2000s Property-based**: Integrated shrinking beats type-based
- **2010s Fuzzing**: Coverage-guided works; fails on encrypted/compressed data
- **2020s LLM**: 80-95% of generated tests are worthless - curation essential

---

## 3. Aligned Decisions

The following decisions were aligned between the orchestrator and user during P4.2 brainstorming.

### 3.1 External List References

**Decision**: Reference URLs to external lists, do not embed copies.

**Rationale**: External lists (BLNS, OWASP) are maintained by their communities. Embedding creates staleness and duplication.

**Implementation**: `references/external-lists.md` contains URLs and descriptions. Data files reference sources but contain curated subsets.

### 3.2 Language-Specific Variants

**Decision**: Include language-specific edge cases as optional extensions.

**Rationale**: Some edge cases are fundamentally language-specific (JS `==` vs `===`, Python `None` vs `False`, Rust ownership). These are valuable but not universal.

**Implementation**:
```
data/
├── strings/           # Universal
├── numbers/           # Universal
└── language-specific/ # Optional extensions
    ├── javascript.yaml  # == vs ===, truthy/falsy quirks
    ├── python.yaml      # None vs False, GIL effects
    └── rust.yaml        # Ownership, borrowing edge cases
```

### 3.3 Concurrency Patterns

**Decision**: Include scenario patterns for state machine and race condition testing, not just data values.

**Rationale**: Concurrency bugs are often overlooked and costlier to fix later. Static data alone cannot express sequence-dependent edge cases.

**Implementation**:
```yaml
# data/concurrency/race-conditions.yaml
category: concurrency
subcategory: race-conditions
type: scenario_pattern  # Not just data values

scenarios:
  double_submit:
    description: "User submits form twice rapidly"
    setup: "Create pending transaction"
    action: "Submit same request 2x with <100ms delay"
    expected_behavior: "Second request rejected or idempotent"
    bugs_caught: ["Duplicate records", "Double charge"]

  concurrent_edit:
    description: "Two users edit same record simultaneously"
    setup: "User A and B both load record #123"
    action: "User A saves, then User B saves"
    expected_behavior: "Conflict detection or last-write-wins"
    bugs_caught: ["Lost updates", "Data corruption"]
```

### 3.4 Update Mechanism

**Decision**: Version metadata in data files + plugin releases + optional helper skill (P6.x).

**Rationale**: Core skill should be simple. Updates ship with plugin. Helper skill enables checking for new patterns without blocking P4.2.

**Implementation**:
1. **Data file metadata**:
```yaml
# data/strings/injection.yaml
metadata:
  version: "1.0.0"
  last_updated: "2026-01-30"
  source_urls:
    - "https://github.com/minimaxir/big-list-of-naughty-strings"
    - "https://owasp.org/www-project-web-security-testing-guide/v42/6-Appendix/C-Fuzz_Vectors"
```

2. **Plugin releases**: Major data updates ship with plugin versions on GitHub

3. **Helper skill (P6.x enhancement)**: `bug-magnet-update` skill that:
   - Fetches latest from BLNS/OWASP URLs
   - Diffs against local data
   - Suggests additions (doesn't auto-modify)
   - User reviews and approves changes

---

## 4. Skill Structure

### 4.1 Directory Layout

**IMPORTANT**: "When to use" and "When not to use" guidance lives in main SKILL.md per Anthropic guidelines. Context folder contains smaller, focused files.

```
skills/bug-magnet-data/
├── SKILL.md                          # Instructions, category overview, when-to-use guards
├── data/
│   ├── strings/
│   │   ├── boundaries.yaml           # Empty, single char, long strings
│   │   ├── unicode.yaml              # Multi-byte, normalization, emoji
│   │   ├── special-chars.yaml        # Quotes, escapes, control chars
│   │   └── injection.yaml            # SQL, XSS, command, path traversal
│   ├── numbers/
│   │   ├── boundaries.yaml           # 0, -1, 1, MAX_INT, MIN_INT
│   │   ├── special.yaml              # NaN, Infinity, -0
│   │   └── precision.yaml            # 0.1+0.2, very large/small
│   ├── booleans/
│   │   └── boundaries.yaml           # true, false, truthy/falsy, null
│   ├── collections/
│   │   ├── arrays.yaml               # Empty, single, large, nested
│   │   └── objects.yaml              # Empty, nested, circular refs
│   ├── dates/
│   │   ├── boundaries.yaml           # Epoch, Y2K38, leap year
│   │   ├── timezone.yaml             # DST, UTC offsets
│   │   └── invalid.yaml              # Feb 30, invalid formats
│   ├── encoding/
│   │   ├── charset.yaml              # ASCII, UTF-8, Latin-1
│   │   └── normalization.yaml        # NFC, NFD, overlong
│   ├── formats/
│   │   ├── email.yaml                # Valid/invalid patterns
│   │   ├── url.yaml                  # Valid/invalid patterns
│   │   └── json.yaml                 # Valid/invalid patterns
│   ├── concurrency/
│   │   ├── race-conditions.yaml      # Scenario patterns
│   │   └── state-machines.yaml       # Invalid transitions
│   └── language-specific/
│       ├── javascript.yaml           # == vs ===, truthy quirks
│       ├── python.yaml               # None vs False, GIL
│       └── rust.yaml                 # Ownership edge cases
├── context/
│   ├── cli-args.md                   # Edge cases for CLI argument testing
│   ├── http-body.md                  # Edge cases for HTTP request bodies
│   ├── file-contents.md              # Edge cases for file I/O
│   ├── db-query.md                   # Edge cases for database operations
│   └── process-spawn.md              # Edge cases for subprocess spawning
└── references/
    └── external-lists.md             # URLs to BLNS, OWASP, etc.
```

### 4.2 Frontmatter

```yaml
---
name: bug-magnet-data
description: >
  Curated edge case test data for boundary testing, verification scripts, and
  test generation. Organized by data type with context-specific guidance.
  50+ years of testing wisdom distilled into small, high-signal collections.
user-invocable: false
agent: haiku
---
```

**Note**: `user-invocable: false` - this is an internal data skill consumed by test-audit, bulwark-verify, and fix-validator.

### 4.3 SKILL.md Structure

The main SKILL.md should include (per Anthropic guidelines):

```markdown
# Bug Magnet Data

Curated edge case test data for boundary testing...

## When to Use This Skill

- Test generation requiring edge case injection
- Verification scripts needing boundary conditions
- Fix validation against edge cases

## When NOT to Use This Skill

- Encrypted/compressed data (edge cases won't penetrate wrapping)
- Pure unit tests with mocked dependencies (edge cases need real execution)
- Performance testing (use load testing tools instead)

## Categories

### Strings
[When to use, examples, bugs caught]

### Numbers
[When to use, examples, bugs caught]

### Injection Patterns
**When to use**: Raw SQL queries, HTML rendering of user input
**When to SKIP**: ORMs with parameterized queries, JSON-only APIs
[Examples, bugs caught]

...
```

### 4.4 Data Format (YAML)

```yaml
# data/strings/boundaries.yaml
metadata:
  version: "1.0.0"
  last_updated: "2026-01-30"
  source_urls: []

category: strings
subcategory: boundaries
bugs_caught:
  - "Empty string crashes (null reference)"
  - "Single character edge cases"
  - "Buffer overflow on long strings"
  - "Off-by-one in length validation"

values:
  empty:
    value: ""
    bugs_caught: ["NullPointerException", "empty input handling"]

  single_char:
    value: "a"
    bugs_caught: ["minimum length validation", "single vs empty distinction"]

  long_string:
    value_template: "a * {length}"
    default_length: 10000
    bugs_caught: ["buffer overflow", "truncation errors", "performance"]
    boundary_note: "Test at your system's actual limit ±1"

  whitespace_only:
    value: "   "
    bugs_caught: ["trim logic errors", "empty vs whitespace distinction"]
```

```yaml
# data/strings/injection.yaml
metadata:
  version: "1.0.0"
  last_updated: "2026-01-30"
  source_urls:
    - "https://owasp.org/www-project-web-security-testing-guide/v42/6-Appendix/C-Fuzz_Vectors"

category: strings
subcategory: injection
severity: security

values:
  sql_basic:
    value: "' OR '1'='1"
    bugs_caught: ["SQL injection via string concatenation"]
    safe_for_automation: true

  sql_destructive:
    value: "'; DROP TABLE users--"
    bugs_caught: ["SQL injection allowing data destruction"]
    safe_for_automation: false
    manual_only: true

  xss_basic:
    value: "<script>alert('XSS')</script>"
    bugs_caught: ["Reflected XSS", "unescaped output"]
    context_required: "HTML rendering"

  command_injection:
    value: "; rm -rf /"
    bugs_caught: ["Command injection in shell execution"]
    safe_for_automation: false
    manual_only: true

  path_traversal:
    value: "../../../etc/passwd"
    bugs_caught: ["Path traversal", "directory escape"]
    safe_for_automation: true
```

### 4.5 Tiered Organization

| Tier | Categories | Usage |
|------|------------|-------|
| **T0 (Always)** | Boundaries (empty/single/max), Null handling | Every test |
| **T1 (Common)** | Basic injection, Unicode basics, Numeric edges | Most tests |
| **T2 (Context)** | Date/time, Advanced injection, Encoding, Concurrency | Domain-specific |
| **T3 (Manual)** | Destructive patterns, Complex scenarios | Manual testing only |

---

## 5. Integration Points

### 5.1 Consumer Skills/Agents

| Consumer | Usage | Data Access |
|----------|-------|-------------|
| **test-audit** | Step 7 rewrites - inject edge cases into verification scripts | Load by category |
| **bulwark-verify** | Enhance generated scripts with boundary testing | Load by component type |
| **bulwark-fix-validator** | Validate fixes against edge cases | Load T0 + T1 tiers |

### 5.2 Component-Type Context Files

Each context file in `context/` provides focused guidance:

```markdown
# context/cli-args.md

## Applicable Categories
- strings/boundaries (empty, long args)
- strings/special-chars (quotes, spaces, backslashes)
- strings/injection (command injection only)
- numbers/boundaries

## Not Applicable
- strings/injection (SQL, XSS) - CLIs don't use these
- formats/email, formats/url - unless CLI processes these

## Examples
[Concrete examples of CLI arg edge case testing]
```

---

## 6. What to Exclude

Based on contrarian and first principles analysis:

| Exclude | Reason |
|---------|--------|
| Exhaustive unicode lists | Focus on normalization/multi-byte boundaries, not every character |
| UI/rendering cases | Not applicable to code testing |
| Arbitrary large sizes | Use conceptual boundaries ("large" = system limit ±1) |
| Every HTTP status code | Services return 6-10, not 50+ |
| Runtime LLM generation | 80-95% waste rate; pre-curate instead |
| Embedded copies of external lists | Reference URLs instead |

---

## 7. Implementation Notes

### 7.1 File Organization Requirement

**CRITICAL**: When implementing the skill:
- **SKILL.md** contains usage guidance, when-to-use/when-not-to-use, category overviews
- **data/** contains YAML files with actual test values
- **context/** contains component-specific guidance (small, focused files)
- **references/** contains external list URLs and descriptions

### 7.2 Data File Metadata

Every data file must include:
```yaml
metadata:
  version: "1.0.0"
  last_updated: "YYYY-MM-DD"
  source_urls: []  # or list of reference URLs
```

### 7.3 Safety Flags

Destructive patterns must be marked:
```yaml
safe_for_automation: false
manual_only: true
```

Consumers should filter these out for automated testing.

---

## 8. References Used

### External Sources

| Source | Contribution |
|--------|--------------|
| [BugMagnet AI Assistant](https://github.com/gojko/bugmagnet-ai-assistant/) | 19-category heuristics structure |
| [Big List of Naughty Strings](https://github.com/minimaxir/big-list-of-naughty-strings) | Curated string edge cases |
| [OWASP Fuzz Vectors](https://owasp.org/www-project-web-security-testing-guide/v42/6-Appendix/C-Fuzz_Vectors) | Security injection patterns |
| [Ordinary Claude Skills - Testing](https://github.com/Microck/ordinary-claude-skills/tree/main/skills_categorized/testing) | Framework-agnostic organization pattern |

### Historical Sources

| Era | Lesson |
|-----|--------|
| 1970s BVA | Boundaries are where bugs hide |
| 2000s Property-based | Integrated shrinking beats type-based |
| 2010s Fuzzing | Coverage-guided works; fails on wrapped data |
| 2020s LLM | 80-95% generated tests worthless - curation essential |

### Research Agent Logs

| Approach | Log File |
|----------|----------|
| Direct | `logs/research-bugmagnet-direct-20260130.yaml` |
| Expert | `logs/research-bugmagnet-expert-20260130.yaml` |
| Contrarian | `logs/research-bugmagnet-contrarian-20260130.yaml` |
| First Principles | `logs/research-bugmagnet-firstprinciples-20260130.yaml` |
| Historical | `logs/research-bugmagnet-historical-20260130.yaml` |

---

*This synthesis document serves as the specification for P4.2 bug-magnet-data skill implementation.*
