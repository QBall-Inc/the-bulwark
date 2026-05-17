# Template: Generator Skill

Use this template when the skill creates structured artifacts (code files, config blocks, documents) by filling templates with inputs. Generators take inputs and emit output — they do NOT conduct interviews and they do NOT package reference content.

**When to use**: The skill's primary value is producing a new file or block of text from inputs. Inputs may come from CLI arguments, prior pipeline stages, or detected project state. Templates live in `templates/`.

---

## File Structure

```
skills/{skill-name}/
├── SKILL.md
└── templates/
    ├── {template-1}.md
    └── {template-N}.md
```

If multiple templates exist (multi-template sub-pattern), include a `templates/manifest.yaml` mapping inputs to template paths.

## Generated SKILL.md Structure

```markdown
---
name: {skill-name}
description: {single-line, trigger-specific, "Use when..." framing}
user-invocable: true
argument-hint: "<inputs>"
version: 1.0.0
author: "Ashay Kubal @ Qball Inc."
---

# {Skill Title}

{One-paragraph summary describing what artifacts the skill emits and from what inputs.}

---

## When to Use This Skill

{Trigger pattern table + DO NOT use for section.}

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Templates** | `templates/{name}.md` | **REQUIRED** | Load before generation |
| **Manifest** (if multi-template) | `templates/manifest.yaml` | **REQUIRED** | Load at Stage 1 to select template |

---

## Usage

```
/{skill-name} {arguments}
```

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill emits artifacts by filling templates. Inputs MUST be validated before generation. Generated artifacts MUST be validated before writing. Follow every item in order. Do NOT return to the user until all applicable items are checked.

- [ ] **Stage 0 — Inputs**: All required inputs collected and validated
- [ ] **Stage 1 — Template Selection** (if multi-template): Manifest consulted; template chosen based on inputs
- [ ] **Stage 1 — Template Load**: Selected template(s) loaded from `templates/`
- [ ] **Stage 2 — Generate**: Template filled with validated inputs (no placeholder text in output — `{NAME}` etc. all substituted)
- [ ] **Stage 3 — Validate**: Generated artifact has correct structure (frontmatter, required sections, valid syntax)
- [ ] **Stage 4 — Write**: Artifact written to the prescribed output path; if path exists, user confirmation obtained
- [ ] **Diagnostics** (if applicable): Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`
- [ ] **Results presented to user** (output path + summary of what was generated)

---

## Workflow

### Stage 0: Inputs

Collect inputs from CLI args, prior pipeline output, or detected state. Validate types and required fields. If a required input is missing, STOP — do NOT generate placeholder output.

### Stage 1: Template Selection

If the skill bundles multiple templates, consult `templates/manifest.yaml` (or equivalent) to pick the right one based on inputs. Document the selection rule in this section.

### Stage 2: Generate

Substitute placeholders in the template with validated inputs. Use unambiguous placeholder syntax (e.g., `{NAME}` or `__NAME__`). After substitution, scan the output for any unsubstituted placeholders — if any remain, STOP.

### Stage 3: Validate

Validate the generated artifact's structure before writing:
- Frontmatter present and well-formed (if applicable)
- Required sections present
- Syntax checks (markdown lint, JSON parse, YAML parse, etc.)

If validation fails, report the specific failure and do NOT write.

### Stage 4: Write

Write to the prescribed output path. If the path already exists, present a diff and obtain confirmation before overwriting.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Required input missing | Report which input is missing. STOP. Do NOT emit placeholder output. |
| Template not found | Report template path attempted. STOP. |
| Manifest selection ambiguous (multi-template) | Report the conflict. Ask user to disambiguate, or STOP. |
| Generated artifact fails validation | Report the validation error. Do NOT write. |
| Output path already exists | Show diff; confirm with user before overwriting. |
```

## Common Sub-Patterns

Generator skills exhibit several recurring sub-patterns. Sub-patterns are additive — pick those that apply to your skill.

### `multi-template`

**Definition**: Skill picks from multiple bundled templates based on input parameters (e.g., language, asset type, archetype).

**When to use**: Multiple distinct output shapes share the same generation workflow but differ in template content.

**Bulwark example**: `bulwark-scaffold` picks from `lib/templates/justfile-{language}.just` based on detected project language.

**How it shapes the skill**: Bundle a manifest (`templates/manifest.yaml`) mapping inputs to template paths. Stage 1 (Template Selection) reads the manifest; Stage 2 (Generate) loads the chosen template. Validate that ALL manifest entries point to existing files at Stage 0.

### `configuration-emitting`

**Definition**: Skill emits a configuration block injected into an existing file rather than creating a new file from scratch.

**When to use**: The output is a settings block, manifest entry, or hook definition that lives inside an existing config file.

**Bulwark example**: `statusline-setup` emits a `statusLine` block written into `settings.json`; does NOT create a new file.

**How it shapes the skill**: Stage 4 (Write) becomes a Read-merge-Write sequence. Validate the existing file's structure first; insert the block at a documented anchor (path expression, JSON key, line marker); write atomically. Document the anchor convention in SKILL.md so users can audit it.

### `interview-augmented`

**Definition**: Skill collects inputs via lightweight user interrogation (one or two AskUserQuestion rounds) rather than CLI arguments alone.

**When to use**: Inputs are hard to specify upfront, but interrogation is bounded — one or two rounds, then generate. If interrogation dominates the workflow, prefer the **Inversion** archetype instead.

**Bulwark example**: None pure — `session-handoff` is a Generator that uses session state plus light prompts; closer to a true Inversion case is `create-skill` itself.

**How it shapes the skill**: Stage 0 (Inputs) becomes a brief interview stage with a hard cap (e.g., max 2 rounds). Beyond two rounds, the skill should be re-classified as Inversion.

---

## Generated Template Structure

Each template in `templates/` should follow this pattern:

```markdown
{Frontmatter or fixed header — what every emitted artifact must contain}

# {Title — fixed structure with placeholders}

{Section 1 with parameterized placeholders like {NAME} or {DATE}}

{Section 2 with more placeholders}

{Closing section — typically generated metadata, not user-input}
```

Use **explicit placeholder syntax** (`{NAME}` or `__NAME__`) so the fill mechanism is unambiguous.

## Guidance for Generator

- Generators are template-driven. SKILL.md describes the WORKFLOW; templates describe OUTPUT SHAPE.
- Bundle templates in `templates/`, NOT in `references/`. References are docs; templates are fillable.
- Use explicit placeholder syntax — avoid ambiguous patterns that overlap with generated content.
- Validate inputs at Stage 0; fail loud if required inputs are missing. NEVER emit placeholders into the output.
- Validate generated artifacts at Stage 3 BEFORE writing — catch malformed output before it lands on disk.
- Keep SKILL.md focused on workflow, not output content — that's what templates are for.
- If interrogation dominates the skill's shape, use the **Inversion** archetype instead. Generators are for "have inputs → emit artifact"; Inversion is for "elicit inputs → emit artifact".
- Generators do NOT spawn sub-agents. If you need sub-agent orchestration around generation, the skill is a **Pipeline** (with a Generator stage as one component).
- Generators typically 100-200 lines for SKILL.md plus templates of any size.
