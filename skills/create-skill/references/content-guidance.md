# Content Guidance

Instruction writing patterns, description rules, and common pitfalls for generating high-quality skills. The Stage 2 generator sub-agent references this to produce skills that activate reliably and instruct clearly.

---

## Description Field Rules

The YAML frontmatter `description` field controls skill discovery and activation. Getting it wrong means the skill never triggers.

### Format Rules

1. **Single line only.** Multi-line descriptions silently break skill discovery (GitHub #9817/#4700).
2. **Maximum 250 characters** — hard cap enforced by `scripts/check-description.ts` per GitHub #881 (descriptions over 250 silently truncate). Aim for ≤200 characters when possible — they display in the `/` menu without secondary truncation.
3. **Start with an action verb.** "Generates...", "Audits...", "Validates..."

### "When to Use" Framing

The description must tell Claude WHEN to load the skill, not just what it does.

**Good — trigger-specific:**
```yaml
description: Generates Claude Code skills from requirements using adaptive interview, complexity classification, and iterative validation. Use when creating new skills, scaffolding skill structure, or generating skills with sub-agent orchestration.
```

**Bad — vague:**
```yaml
description: A tool for creating skills.
```

**Bad — too broad:**
```yaml
description: Helps with skill development and management across projects.
```

### Pattern

```
{Action verb} {what it does} {using what method}. Use when {trigger condition 1}, {trigger condition 2}, or {trigger condition 3}.
```

The trigger conditions are the most important part. They determine whether Claude loads the skill when the user asks for something.

---

## Instruction Writing Patterns

How to write skill instructions that Claude actually follows.

### Binding Language (DEF-P4-005)

Without explicit binding language, Claude treats skill instructions as suggestions and skips steps it deems unnecessary.

**Pattern: Pre-Flight Gate**

Place a blocking gate before the main workflow. This forces acknowledgment before execution.

```markdown
## Pre-Flight Gate (BLOCKING)

**STOP. Before ANY analysis, you MUST acknowledge what this skill requires.**

### What You MUST Do
1. [Step 1]
2. [Step 2]

### What You MUST NOT Do
- Do NOT skip [specific step]
- Do NOT perform [agent's work] yourself
```

**Pattern: MANDATORY sections**

Mark critical steps explicitly:

```markdown
### Stage 2: Generate (MANDATORY)

You MUST spawn a Sonnet sub-agent for generation. Do NOT generate the output yourself.
```

**Pattern: Anti-thought traps**

Address the specific rationalization Claude uses to skip steps:

```markdown
If you find yourself thinking "I can do this faster without a sub-agent" — STOP.
That thought pattern violates SC1-SC2. The pipeline exists for bias avoidance.
```

**Pattern: Top-of-File Execution Checklist**

For multi-stage pipeline skills, place a binding execution checklist at the top of SKILL.md — after frontmatter, overview, "When to Use", Dependencies, and (optionally) Usage, but **before** the substantive Pipeline/Stages body. Bottom-of-file checklists are ignored: Claude commits to its execution plan before reaching them.

````markdown
## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill uses a {N}-stage pipeline. You are the orchestrator. Follow every item in order. Do NOT return to the user until all applicable items are checked.

- [ ] **Stage 0 — Pre-Flight**: Arguments parsed (description, name, or --doc)
- [ ] **Stage 1 — Classify**: Classification presented to user via AskUserQuestion
- [ ] **Stage 2 — Generate**: Sonnet sub-agent spawned via Task tool (you do NOT generate the files yourself)
- [ ] **Stage 3 — Validate**: /anthropic-validator invoked (manual review is NOT a substitute)
- [ ] **Stage 6 — Diagnostics**: Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`
````

**Placement rule**: immediately after metadata sections (frontmatter → overview → When to Use → Dependencies → optional Usage), before Pipeline/Stages content that describes HOW.

**Item format**: `- [ ] **Stage N — Phase**: Imperative description`. Use MUST / MUST NOT / no exceptions modifiers inline where the stage has historically been skipped.

**Evidence**: `plan-creation`, `bulwark-brainstorm`, `create-skill`, `create-subagent` all use this pattern. Without it, pipeline skills silently skip stages (confirmed regression in plan-creation TC3 Round 1; fixed in Round 2 by moving the checklist to the top).

### Good vs Bad Instructions

**Good — specific, actionable, ordered:**
```markdown
## Stage 1: Classify

1. Read the interview answers from Stage 0
2. Apply Decision A (Context Mode) using the decision tree in references/decision-framework.md
3. Apply Decision B (Sub-Agent Pattern)
4. Apply Decision C (Supporting Files)
5. Map the three decisions to a template using the Decision → Template Mapping table
6. Present classification to user via AskUserQuestion for confirmation
```

**Bad — vague, hand-wavy:**
```markdown
## Classification

Analyze the user's requirements and determine the best approach for the skill.
Consider factors like complexity, context needs, and file structure.
```

**Bad — too many options without guidance:**
```markdown
## Generation

You can either:
- Generate the skill directly
- Use a sub-agent
- Ask the user to provide more details
- Skip generation if the skill seems too complex

Choose the best approach based on the situation.
```

### Instruction Density

- Each stage should have 3-8 concrete steps
- Steps should be imperative: "Read X", "Write Y", "Spawn Z"
- Avoid conditional trees deeper than 2 levels (use a reference table instead)

---

## Common Pitfalls

Issues discovered through production usage of Bulwark skills.

### Pitfall 1: Multi-Line YAML Description

```yaml
# BROKEN — skill won't appear in / menu
description: >
  This skill does many things
  across multiple lines.

# CORRECT — single line
description: This skill does many things across multiple lines.
```

**Impact**: Silent failure. Skill exists on disk but never activates.

### Pitfall 2: Fork + Guidelines = No-Op

A skill with `context: fork` that contains only guidelines (no tool calls, no sub-agents) runs in an isolated context, reads the guidelines, and returns without doing anything useful. The forked context has no access to the user's conversation or files being discussed.

```yaml
# BROKEN — fork with only guidelines, no actionable work
context: fork
---
## Guidelines
- Write clean code
- Follow best practices
```

**Resolution**: Use inline (no fork) for guideline/knowledge skills. Fork is for skills that perform independent multi-step work.

### Pitfall 3: Over-Elaborate Output Specifications

Specifying every field, section, and format in exhaustive detail causes the generator to focus on format compliance rather than content quality.

**Better approach**: Provide a template file in `templates/` and reference it. Let the skill focus on WHAT to produce, not HOW to format every line.

### Pitfall 4: Missing Activation Triggers

A skill without clear trigger patterns in its description and "When to Use" section will never be loaded by Claude, regardless of how good its instructions are.

**Minimum viable activation**:
1. Description field with trigger verbs
2. "When to Use" section with trigger pattern table
3. "DO NOT use for" section to prevent false activations

### Pitfall 5: Sub-Agent Work Done by Orchestrator

When a skill specifies "spawn a sub-agent for X", Claude may skip spawning and do the work itself. This defeats bias separation and pipeline observability.

**Prevention**: Use the binding language patterns (Pre-Flight Gate, MUST/MUST NOT, anti-thought traps).

### Pitfall 6: Undocumented Dependencies

Skills that silently depend on other skills, scripts, or project structure break when used outside the original project.

**Prevention**: Declare all dependencies in a Dependencies table:

```markdown
## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Prompting** | `subagent-prompting` skill | REQUIRED | Before spawning any sub-agent |
| **Templates** | `templates/output.md` | REQUIRED | Include in sub-agent prompt |
```

---

## Activation Tuning

How to improve the chance Claude loads your skill when the user needs it.

### Trigger Verb Coverage

Include multiple trigger verbs in the description to catch different phrasings:

```yaml
# Covers: "create", "scaffold", "generate", "build"
description: Generates Claude Code skills from requirements... Use when creating new skills, scaffolding skill structure, or generating skills...
```

### "When to Use" Table

The table format is more reliable than prose for activation:

```markdown
| Trigger Pattern | Example User Request |
|-----------------|---------------------|
| Skill creation  | "Create a new skill", "Make a skill for X" |
| Scaffolding     | "Scaffold a skill", "Set up a new skill" |
| Generation      | "Generate a skill that does X" |
```

### "DO NOT Use For" Section

Negative triggers prevent false activations that waste tokens:

```markdown
**DO NOT use for:**
- Editing existing skills (edit directly)
- Debugging skill issues (use issue-debugging)
```

---

## Output Path Conventions

Generated skills MUST use `$PROJECT_DIR` as the prefix for all output paths. `$PROJECT_DIR` is the project root directory (where `.claude/` lives). Without this prefix, paths resolve relative to CWD — which during skill execution is often the skill directory itself (e.g., `.claude/skills/{skill-name}/`), causing output to be written into the skill directory.

### Three Output Categories

| Category | Path Convention | What Goes Here |
|----------|----------------|----------------|
| **Intermediate output** | `$PROJECT_DIR/logs/{skill-name}/` | Sub-agent reports, stage outputs, working files that feed the next stage |
| **Diagnostics** | `$PROJECT_DIR/logs/diagnostics/{skill-name}-{timestamp}.yaml` | Pipeline execution metadata, timing, error counts |
| **Deliverables** | `$PROJECT_DIR/artifacts/{skill-name}/{slug}/` | Synthesis documents, final reports, generated code — anything the user consumes directly |

### Rules

1. **Always prefix with `$PROJECT_DIR/`** — never use bare `logs/` or `artifacts/`
2. **Synthesis is a deliverable, not a log** — write to `artifacts/`, not `logs/`
3. **Sub-agent output is intermediate** — write to `logs/`, the next stage reads from there
4. **Diagnostics are always in `logs/diagnostics/`** — never in `artifacts/`
5. **Never write output into the skill directory** (`.claude/skills/{name}/`) or CWD

### Example Paths

```
$PROJECT_DIR/logs/market-research/analyst.md           # intermediate (sub-agent output)
$PROJECT_DIR/logs/market-research/competitor.md         # intermediate (sub-agent output)
$PROJECT_DIR/logs/diagnostics/market-research-20260222.yaml  # diagnostic
$PROJECT_DIR/artifacts/market-research/q1-analysis/synthesis.md  # deliverable
```

---

## Sub-Pattern Catalog

Skills are classified into one of 7 archetypes (see `decision-framework.md`), but real skills are often composites. **Sub-patterns** are documented additive variants within each archetype that the generator surfaces during classification. They are NOT new archetypes — they are guidance for how to shape the SKILL.md within the chosen archetype's template.

**Composability principle**: Sub-patterns are additive, not exclusive. A single skill MAY exhibit multiple sub-patterns simultaneously. Examples from Bulwark's installed base:

- `bulwark-research` is Research + `source-tier-disciplined` + `reviewer-validated`
- `code-review` is a Pipeline that is `reviewer-orchestrating` AND has constituent Reviewer stages
- `governance-protocol` is Tool Wrapper + `context-injected`
- `bulwark-statusline` is Script-driven + `hook-orchestrated`

When the user selects sub-patterns at Stage 1 classification, the Stage 2 generator MUST include a section in the generated SKILL.md documenting each chosen sub-pattern (definition + how it shapes the skill). Reference the matching `references/template-{archetype}.md` → `## Common Sub-Patterns` for canonical definitions.

### Catalog (sourced from Part F audit at `docs/internal/existing-skills-archetype-mapping.md`)

| Archetype | Sub-Pattern | Definition | Bulwark Examples |
|-----------|-------------|------------|------------------|
| Generator | `multi-template` | Picks from multiple bundled templates based on input parameters | `bulwark-scaffold` |
| Generator | `configuration-emitting` | Emits a config block injected into an existing file (settings.json, etc.) | `statusline-setup` |
| Generator | `interview-augmented` | Lightweight user interrogation (1-2 rounds) before template fill | (boundary case — heavier interrogation routes to Inversion) |
| Tool Wrapper | `context-injected` | Loaded via hook (typically SessionStart) into Claude's context; `user-invocable: false` | `governance-protocol` |
| Tool Wrapper | `schema-convention` | Defines a contract or output schema other assets follow | `subagent-output-templating`, `subagent-prompting` |
| Tool Wrapper | `methodology` | Pure how-to reference applied as agent context | `issue-debugging`, `test-fixture-creation` |
| Tool Wrapper | `pattern-catalog` | Library of named patterns consumed by orchestrating skills | `pipeline-templates`, `component-patterns`, `assertion-patterns` |
| Tool Wrapper | `curated-data-library` | Manifest + loading rules for bundled data files | `bug-magnet-data` |
| Research | `reviewer-validated` (default ON) | Embeds a Reviewer-shaped Critical Evaluation Gate to ground findings | `bulwark-research`; recommended for `plan-creation` triad |
| Research | `source-tier-disciplined` | Web-search-heavy with explicit T1/T2/T3 source classification | `bulwark-research`, `product-ideation-market-researcher` |
| Pipeline | `reviewer-orchestrating` | Constituent stages predominantly Reviewer-shaped | `code-review`, `test-audit`, `fix-bug` |
| Pipeline | `research-orchestrating` | Constituent stages predominantly Research-shaped | `product-ideation`, `plan-creation`, `bulwark-brainstorm --exploratory` |
| Pipeline | `generator-orchestrating` | Includes Generator stages emitting artifacts from prior-stage findings | `continuous-feedback` (Proposer stage), `bulwark-verify` (Generate stage) |
| Reviewer | `standalone` | User-invoked directly; verdict presented to user | `code-review`, `mock-detection`, `bulwark-standards-reviewer` |
| Reviewer | `pipeline-stage` | Operates as single stage within larger orchestrator | `test-classification` (within `test-audit`), `plan-creation-qa-critic` |
| Reviewer | `multi-source` | Reads multiple prior artifacts; synthesises holistic verdict | `product-ideation-strategist`, `plan-creation-qa-critic` |
| Inversion | `generator-coupled` (canonical) | Interview elicits inputs that feed a Generator-style template fill | `create-skill`, `create-subagent` |
| Script-driven | `hook-orchestrated` | Bundled script invoked by Claude Code hook (statusLine, SessionStart) | `bulwark-statusline` |

### How Sub-Patterns Shape the Generated Skill

Each sub-pattern's full definition (when to use, how it shapes the skill, Bulwark examples) lives in the matching template's `## Common Sub-Patterns` section. When the generator includes a sub-pattern, the generated SKILL.md should:

1. Reference the sub-pattern by name in the When to Use section ("This skill follows the Tool Wrapper archetype with the `methodology` sub-pattern.")
2. Include a brief sub-pattern documentation section quoting the canonical definition.
3. Apply the sub-pattern's shape directives (e.g., `context-injected` → `user-invocable: false` + hook setup docs).

### Path B (Matrix Scoring) — Deferred

Documenting sub-patterns is the prerequisite data foundation for a future Path B (matrix scoring + composite template generation) if real users hit the limits of "primary archetype + sub-pattern guidance." For v1.2, sub-patterns are documented additive guidance only.

---

## SKILL.md Size Guidance

SKILL.md size is a forcing function for progressive disclosure. Skills that grow past a few hundred lines lose LLM coherence (the model paraphrases instead of executing) and increase load-time cost on every invocation. Keep SKILL.md focused on workflow; move detail into `references/`, `templates/`, or `examples/`.

### Tiered Line Caps (memo D8 amended S107)

The generator enforces three tiers of friction, scaling with line count:

| Tier | Lines | Behavior |
|------|-------|----------|
| Advisory | 200 | Soft note in Stage 5 summary — "Skill is N lines; consider extracting reference content if it grows." Per-archetype targets remain (Generator 200, Pipeline 400, etc.). |
| Strong warn | 500 | Loud warning at Stage 2 generation + Stage 5 summary — "Skill is N lines; strongly recommend splitting reference content into `references/`. Continued use without split risks load-time penalties and reduced LLM coherence." |
| Hard cap | 600 | Stage 2 STOP — generator MUST refuse to emit a single SKILL.md exceeding 600 lines. Returns a refactor proposal listing which sections should move to `references/{name}.md` or `examples/{name}.md`. User confirms refactor approach, then re-generation. |

**Why 600 and not 500?** Anthropic's published guidance recommends ≤500 lines for SKILL.md. Bulwark surfaces 500 as the Strong-warn tier — visible to the user but not a refusal. The Hard-cap at 600 gives a 100-line buffer above Anthropic's recommendation: skills in the 500-600 range get a loud nudge to split, skills above 600 get a forced refactor. The 100-line gap is the design-intent zone where progressive disclosure should kick in but the skill isn't yet structurally broken.

### Per-Archetype Targets (Soft)

Different archetypes have natural size profiles. The Stage 2 generator's per-archetype target is the practical soft cap; the universal 200/500/600 tiers are additional guardrails:

| Archetype | Target | Reason |
|-----------|--------|--------|
| Tool Wrapper | 150 | Mostly content-injection or schema reference; SKILL.md is a thin loader |
| Generator | 200 | Workflow + template references; bulk lives in templates/ |
| Reviewer | 250 | Audit logic + severity rubric; fits comfortably |
| Inversion | 350 | Interview structure + Q catalog adds material vs. Generator |
| Pipeline | 400 | Multi-stage orchestration + sub-agent references |
| Research | 400 | Multi-viewpoint setup + reviewer-validated gate |
| Script-driven | 400 | Script invocation + parsing logic + output schema |

A skill that materially exceeds its per-archetype target should split before approaching the universal 200 advisory tier.

### What to Extract First

When refactoring a too-long SKILL.md:

1. **Extract content reference catalogs** to `references/{name}-catalog.md` — sub-pattern lists, error tables with detailed remediation, multi-row decision matrices.
2. **Extract templates** to `templates/{name}.md` — output schemas, frontmatter examples, file-structure scaffolds.
3. **Extract examples** to `examples/{name}.md` — worked traces of stage execution, before/after fixtures.
4. **Keep in SKILL.md**: workflow stages (with brief inline summaries), top-of-file BINDING checklist, Dependencies table, Usage section, Error Handling table, Token Budget Management table.

If a section is consulted in only one stage, it can usually be extracted. If it is referenced across multiple stages or is the orchestration spine, it stays in SKILL.md.

---

## Cross-File Consistency

Skills that bundle `templates/`, `references/`, or `scripts/` face a class of silent functional bugs: SKILL.md may state rules (validation logic, character sets, error conditions, output schemas) that mirror or reference content in supporting files. When the two surfaces drift, both files individually compile clean — the disagreement only manifests at runtime, on edge-case inputs.

### Canonical Example (S107 slug-from-title probe)

The S107 startup probe generated a Generator-archetype skill `slug-from-title`. The result:

- `templates/slug-algorithm.md` Step 4 said: "Replace any sequence of one or more characters that are not Unicode letters or digits with a single hyphen." (Unicode-preserving.)
- SKILL.md Stage 3 (Validate) said: "All characters are lowercase ASCII letters (`a-z`), digits (`0-9`), or hyphens (`-`)." (ASCII-only.)

A title containing accented characters (`café-dispatch`) would pass the algorithm cleanly, then fail Stage 3 validation, producing a spurious "validation failed" error and no slug. Both files individually pass anthropic-validator's structural checks. The Sonnet sub-agent that generated them missed the disagreement; anthropic-validator caught it via cross-file consistency reasoning.

This is not a one-off. The risk shape recurs whenever SKILL.md content mirrors or references supporting-file content.

### Common Disagreement Shapes

| Shape | Example |
|-------|---------|
| Character set mismatch | Algorithm preserves Unicode + validation accepts ASCII only (canonical) |
| Error condition mismatch | Template says "STOP if input empty" + SKILL.md says "STOP if input < 3 chars" |
| Output format mismatch | Template emits JSON + SKILL.md describes YAML output |
| Schema field mismatch | Template defines fields A/B/C + SKILL.md error handling references field D |
| Validation rule mismatch | Template constraint "max 80 chars" + SKILL.md gate "max 100 chars" |
| Step count mismatch | Template lists 6 algorithm steps + SKILL.md Stage 2 enumerates 5 inline |
| Default value mismatch | Template default `--mode standard` + SKILL.md examples use `--mode strict` |

### Two-Layer Defense (memo D11, S107)

`create-skill` enforces cross-file consistency at two layers:

**Layer 1 — Stage 2 generator-side prevention (CONSTRAINT)**:
The Sonnet sub-agent prompt instructs cross-file scanning before returning. If the skill bundles `templates/`, `references/`, or `scripts/`, the sub-agent must scan for cross-file claims and confirm agreement. Disagreements are HIGH-severity functional bugs to fix BEFORE returning, not defer to validation.

**Layer 2 — Stage 3 orchestrator-side detection (manual check)**:
The Stage 3 exit gate adds a "Cross-file consistency check" item. The orchestrator scans SKILL.md for content that mirrors or references template/reference content; verifies agreement. If a disagreement is found, treat as HIGH finding and route to Stage 4 refinement.

### Why Defense-in-Depth (Not Either-Or)

Layer 1 is prevention (cheaper to fix at generation time). Layer 2 is detection (catches what Layer 1 missed). Both layers use LLM judgment — the Sonnet sub-agent at Layer 1, the orchestrator at Layer 2. There is no scripted detection (`check-cross-file-consistency.ts`) because cross-file claim shapes are too varied for a generic script. If empirical evidence later shows the LLM-only path is unreliable, escalate to scripted detection in a future P10.x.

### Authoring Skills Manually

If you author a skill by hand (without `create-skill`), apply the same discipline:

1. After writing SKILL.md and supporting files, list every claim in SKILL.md that mirrors or references content in a supporting file (validation rules, character sets, error conditions, output schemas, algorithm step counts).
2. For each mirror, open both files and verify they agree.
3. If they disagree, decide which is canonical (usually the supporting file is canonical because it is closer to implementation) and update the other to match — or refactor SKILL.md to reference the supporting file by name instead of duplicating its content.

---

## Generate-and-Customize Contract

All generated skills are scaffolds, not production-ready output. This must be communicated explicitly.

### Required Disclaimer

Every generated skill should include this understanding in the post-generation summary:

```
This is a scaffold — a starting point for your skill. You should:
1. Review and customize the generated instructions
2. Test activation by asking Claude to invoke it
3. Iterate on trigger patterns until activation is reliable
4. Add domain-specific content to reference files
```

### Why This Matters

Research convergence across Rails generators, Yeoman, Create React App, and AI-era generators: output is always a starting point. Making this explicit prevents user disappointment and sets correct expectations.

---

## Eval Scaffolding (Layer 1 DATA)

Every generated skill ships with `evals/` data so behavior can be baselined and regression-tested. The Stage 2 generator MUST emit:

| File | When | Purpose |
|------|------|---------|
| `evals/evals.json` | Always | One concrete starter test (seeded from Q1 examples) + assertion shell |
| `evals/triggers.json` | Always | 3-5 should-trigger + 3-5 should-not-trigger queries (seeded from Q1) + `<<TODO>>` slots for the rest |
| `evals/compliance.json` | `grading_mode = subjective` only (Research, Inversion, or override) | Stage execution checks (one per declared SKILL.md pipeline stage) |

**Default `grading_mode` per archetype** (Stage 1 resolves; author may override):
- `objective` — Generator, Tool Wrapper, Pipeline, Reviewer, Script-driven
- `subjective` — Research, Inversion

**Sub-patterns NEVER flip `grading_mode`** (Model A locked at S109 startup) — they add assertion templates within the existing mode.

**Read `references/eval-scaffolding.md`** for per-archetype JSON shapes, placeholder substitution markers (`<<SKILL_NAME>>`, `<<INVOCATION_EXAMPLE_1>>`, etc.), and the sub-pattern × eval impact table. The schema lock is in `references/eval-shape.md`.

**Generate-and-customize contract applies**: scaffold ONE concrete starter test from Q1 + leave explicit `<<TODO>>` markers for additional tests/queries. Authors fill the rest after generation.

---

## Scripts Convention

A generated skill ships a `scripts/` directory iff `bundles_scripts = true` (Stage 1 decision). Trigger conditions:

- **Always** for archetype = Script-driven (canonical)
- **On opt-in** for non-Script-driven archetypes — author confirms via Stage 1 follow-up

When `bundles_scripts = true`, Stage 2 emits:

| File | Purpose |
|------|---------|
| `scripts/.gitkeep` | Empty file — preserves directory in git |

Stage 2 does **not** generate concrete script files (no archetype-generic starter is useful enough to outweigh the noise). Authors write their scripts post-scaffold; refer to existing skills for patterns (`create-skill/scripts/run-loop.ts` for TS-via-bun; `bulwark-scaffold/scripts/` for shell).

**Required SKILL.md sections** when `bundles_scripts = true`:
- **Runtime Prerequisites** — note bun on PATH (cross-link to P10.11 brief) for TS-via-bun scripts
- **Permissions Setup** — list `Bash(bun:*)`, `Bash(bash:*)`, `Bash(just:*)` per scripts-conventions.md
- **Invocation convention** — use `${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/...` (NOT `$CLAUDE_PLUGIN_DIR` — non-existent; latent bug source per Session 103 finding)

**Justfile recipes** wrap scripts with `bun "${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/<file>.ts" "{{args}}"` (always quote `${CLAUDE_PLUGIN_ROOT}` and parameters per SEC-008).

**Read `references/scripts-conventions.md`** for the full convention.

---

## Skill Version + Migration Checklist

Every generated skill ships with `version: 1.0.0` in its frontmatter (E.4 — emitted by Stage 2 generator). This is a Bulwark-adopted field (P10.3 will allowlist it in `anthropic-validator`).

### Versioning Policy (Semver-Flavored)

| Bump Type | When To Use | Examples |
|-----------|-------------|----------|
| **Patch** (1.0.0 → 1.0.1) | Typo fixes, wording clarifications, internal refactors that don't change behavior | Description rewording; reference file polish; whitespace cleanup |
| **Minor** (1.0.0 → 1.1.0) | New features, additive sub-patterns, new optional sections | New sub-pattern documentation; new optional dependency; expanded examples |
| **Major** (1.0.0 → 2.0.0) | Breaking changes — removed sections, changed prompt contracts, renamed sub-patterns | Removing a stage; renaming the skill; changing required arguments |

Bump the version every time you ship a meaningful change. Don't bump for no-op edits (whitespace, comments).

### Migration Checklist (When `create-skill` Templates Update)

`create-skill`'s templates and content-guidance evolve over time. When a generated skill needs to align with a newer template version, follow this checklist:

1. **Read the changelog** — check `create-skill`'s recent SKILL.md history (`git log skills/create-skill/SKILL.md`) and the per-Part briefs in `plans/task-briefs/P10.2-part-*.md` for what changed.
2. **Identify affected templates** — which template-{archetype}.md changed, and does your skill use it?
3. **Review your skill against the new template** — open `references/template-{your-archetype}.md` from the latest `create-skill` and compare section-by-section. Spot deltas (new sections, renamed fields, changed checklist items).
4. **Re-run interview sections selectively** — for unchanged areas, no action. For changed areas, re-run the relevant Stage 1 sub-pattern selection or Stage 0 interview question manually and update your SKILL.md.
5. **Re-validate** — `just check-description {your-skill}/SKILL.md`, `just check-skill-size {your-skill}/SKILL.md`, then `/anthropic-validator skills/{your-skill}/`. All must PASS before merging.
6. **Re-baseline evals** — if the change affects scaffolded `evals/*` shapes (T-019/T-020), update them to the latest schema per `references/eval-shape.md`. Re-run `just eval-skill {your-skill}` to confirm the new shape passes.
7. **Bump version** — patch for cosmetic alignment, minor for new sub-pattern adoption, major for archetype reclassification.

### Why No In-Place Update Engine

A Copier-style template-update engine (auto-merge new template content into existing skills) is **deferred to v1.3+**. v1.2 ships migration guidance only. Rationale per Memo D9: in-place merging across LLM-generated content is fragile (LLM output isn't a deterministic template fill); manual migration with the checklist is more reliable.
