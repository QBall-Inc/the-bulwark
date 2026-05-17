# Template: Tool Wrapper Skill

Use this template when the skill packages a library, CLI, API, convention, methodology, or domain knowledge as on-demand context for Claude or other skills to consume. Tool Wrappers are reference-heavy with light workflow logic.

**When to use**: The skill's primary value is providing reference content (rules, patterns, schemas, conventions, data, methodology) that Claude or other skills load when needed. The skill itself does NOT produce a new artifact and does NOT orchestrate sub-agents.

---

## File Structure

```
skills/{skill-name}/
├── SKILL.md
└── references/
    ├── {domain-1}.md
    ├── {domain-2}.md
    └── {domain-N}.md
```

Optional `data/`, `assets/`, or other directories for non-markdown reference content (curated-data-library sub-pattern).

## Generated SKILL.md Structure

```markdown
---
name: {skill-name}
description: {single-line, trigger-specific, "Use when..." framing}
user-invocable: {true/false}  # context-injected sub-pattern: false; most others: true
version: 1.0.0
author: "Ashay Kubal @ Qball Inc."
---

# {Skill Title}

{One-paragraph summary: what reference content this skill packages and when consumers should load it.}

---

## When to Use This Skill

{Trigger pattern table + DO NOT use for section.}

{For consumer-only skills (user-invocable: false), document the consumer interface explicitly: which skills/agents reference this and under what conditions.}

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Reference content** | `references/{name}.md` | **REQUIRED** | Per Reference Map below |

**Loading semantics**: Tool Wrappers expose reference content to consumers — they are not orchestrators. Consumers load specific reference files based on the situation.

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill packages reference content. Consumers MUST load relevant reference files before applying the conventions described. Follow every item before considering the skill applied:

- [ ] **Skill discovered** (auto-loaded via skill matching, hook injection, or explicit consumer reference)
- [ ] **Relevant reference file(s) loaded** per the Reference Map below
- [ ] **Conventions applied** to the consumer's task per the loaded reference(s)
- [ ] **No invention beyond the reference** — when reference content does not cover the case, escalate or ask; do NOT improvise

---

## Reference Map

| Situation | Load |
|-----------|------|
| {Situation 1} | `references/{file-1}.md` |
| {Situation 2} | `references/{file-2}.md` |
| {Situation N} | `references/{file-N}.md` |

---

## Instructions

The body of the SKILL.md describes WHEN and HOW to apply the reference content, not the content itself.

### Pattern: {Name}

When {situation}, the consumer should:

1. Load `references/{file}.md`
2. Apply the {convention/pattern/schema} described
3. {Action — match output, validate input, classify, etc.}

(Repeat per pattern as needed.)
```

## Common Sub-Patterns

Tool Wrappers exhibit several recurring sub-patterns. Sub-patterns are additive — pick those that apply.

### `context-injected`

**Definition**: Skill is loaded into Claude's context via a hook (typically SessionStart) rather than being discovered by skill matching. `user-invocable` is `false`.

**When to use**: The skill's content must be active for the entire session and is NOT triggered by user requests.

**Bulwark example**: `governance-protocol` is injected via `SessionStart` hook calling `inject-protocol.sh`, which reads SKILL.md and echoes content into the session context.

**How it shapes the skill**:
- Set `user-invocable: false` in frontmatter.
- Document the loading hook (script path, hook event) in the Instructions section.
- The corresponding hook script is part of the skill's distribution (in `scripts/hooks/` or referenced by `hooks/hooks.json`).
- Reference Map is replaced by Loading Sequence (what fires, what reads what, what gets injected).

### `schema-convention`

**Definition**: Skill defines a contract (schema, format, output shape) that OTHER assets follow. Consumers reference the schema when authoring matching artifacts.

**When to use**: You're standardizing the SHAPE of something (sub-agent log format, frontmatter conventions, prompt structure).

**Bulwark example**: `subagent-output-templating` defines the YAML schema for sub-agent log output; `subagent-prompting` defines the 4-part prompt template. Other skills reference both when prompting sub-agents.

**How it shapes the skill**:
- `references/` is structured around the schema (one file per major schema section, or one comprehensive schema file).
- The Instructions section provides a Quick Reference + compliance checklist.
- Include a "What NOT to do" section to flag common mis-uses of the schema.

### `methodology`

**Definition**: Skill is a methodology reference (steps, principles, decision rubrics) loaded as agent or skill context.

**When to use**: You're documenting HOW to do something rigorously (root cause analysis, fixture creation, debugging) rather than defining a structural shape.

**Bulwark example**: `issue-debugging` provides 5 Whys, hypothesis-driven debugging, and impact-mapping methodology consumed by debugging agents.

**How it shapes the skill**:
- `references/` contains methodology breakdowns (one per principle or stage).
- Instructions section provides a "When applying this methodology, load these references" map.
- Often paired with anti-pattern documentation ("here's what NOT to do").

### `pattern-catalog`

**Definition**: Skill is a library of named patterns consumed by other orchestrating skills.

**When to use**: You have a finite set of named patterns (verification scripts, pipeline definitions, assertion forms) reused across many contexts.

**Bulwark example**: `pipeline-templates` catalogs F# pipeline definitions consulted by orchestrators; `component-patterns` catalogs verification approaches consumed by `bulwark-verify`; `assertion-patterns` catalogs T1-T4 violation transformations.

**How it shapes the skill**:
- `references/` contains one file per pattern (or one comprehensive catalog file with named sections).
- Instructions section provides a Pattern Index table mapping situation → pattern file.
- Patterns are typically consumed by Pipeline skills, not invoked directly.

### `curated-data-library`

**Definition**: Skill packages curated data files (test fixtures, edge cases, reference datasets) with loading rules.

**When to use**: The skill's value is the DATA, not the prose. Consumers use the data programmatically.

**Bulwark example**: `bug-magnet-data` packages curated edge-case test data with type-specific loading guidance.

**How it shapes the skill**:
- Data lives in a non-markdown directory (e.g., `data/`, `assets/`).
- `references/` documents the data manifest, loading conventions, tier classification.
- Instructions section provides a Data Map: situation → data file path.
- Schema for the data files (CSV columns, JSON structure) MUST be documented in references.

---

## Generated Reference File Structure

Each file in `references/` should follow this pattern:

```markdown
# {Domain Name}

{Brief description of what this reference contains and when consumers should load it.}

---

## {Section 1}

{Content organized for consumption — tables for lookup, lists for iteration, prose for context.}

## {Section 2}

{Additional sections as needed.}
```

## Guidance for Generator

- Tool Wrappers are reference-heavy. Bulk of value lives in `references/`, not in SKILL.md.
- SKILL.md is the loader/index — describes WHEN and HOW to load reference files; does NOT duplicate their content.
- Reference files: 50-150 lines each. Enough to be useful, not so much they consume token budget.
- Reference files: organize content by how it'll be consumed (lookup tables, iteration lists, prose context).
- Name reference files by domain concept, NOT by step number (e.g., `security-patterns.md` not `step-2-data.md`).
- Include a Reference Map (or Pattern Index for catalog sub-pattern) table in SKILL.md — this is how consumers know what to load.
- Sub-pattern selection determines structure: `context-injected` skills set `user-invocable: false` and document the hook; `pattern-catalog` skills add a Pattern Index; `curated-data-library` skills bundle non-markdown data.
- Tool Wrappers do NOT spawn sub-agents. If you need to orchestrate, use the **Pipeline** archetype.
- Tool Wrappers do NOT emit new artifacts. If you need to generate, use the **Generator** archetype.
- Tool Wrappers typically 80-150 lines for SKILL.md plus reference files.
