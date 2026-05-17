# Template: Reviewer Skill

Use this template when the skill scores existing artifacts (code, tests, docs, plans, configurations) against a checklist or criteria and produces severity-classified findings. Reviewers are READ-ONLY — they do NOT modify the subject artifact.

**When to use**: The skill's purpose is to AUDIT or VALIDATE existing material. Output is structured findings (PASS/FAIL with rationale, severity-classified violations, BUY/HOLD/SELL verdict, etc.). Modifications to the subject are EXPLICITLY out of scope — the skill's value is the audit, not the fix.

---

## File Structure

```
skills/{skill-name}/
├── SKILL.md
├── references/
│   ├── {checklist}.md           # The criteria the reviewer applies
│   └── {severity-rubric}.md     # How findings are classified
└── templates/
    └── findings-output.yaml     # Structured findings template
```

## Generated SKILL.md Structure

```markdown
---
name: {skill-name}
description: {single-line, trigger-specific, "Use when..." framing}
user-invocable: true
argument-hint: "<file or directory to review>"
version: 1.0.0
author: "Ashay Kubal @ Qball Inc."
---

# {Skill Title}

{One-paragraph summary: what artifacts are reviewed, what dimensions are scored, what the output is.}

---

## When to Use This Skill

{Trigger pattern table + DO NOT use for section.}

**This skill is READ-ONLY.** It produces findings about the subject artifact; it does NOT modify it. To FIX issues found, the user must invoke a separate skill (e.g., `fix-bug`, manual edits, or an implementer agent).

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Checklist** | `references/{checklist}.md` | **REQUIRED** | Load before review begins |
| **Severity rubric** | `references/{severity-rubric}.md` | **REQUIRED** | Load before classifying findings |
| **Findings template** | `templates/findings-output.yaml` | **REQUIRED** | Use for output structure |

---

## Usage

```
/{skill-name} <subject-path> [flags]
```

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill is a read-only reviewer. The subject artifact MUST NOT be modified. Findings MUST be severity-classified per the rubric. Follow every item in order:

- [ ] **Stage 0 — Pre-Flight**: Subject artifact(s) exist and are readable
- [ ] **Stage 0 — Pre-Flight**: Checklist and severity rubric loaded
- [ ] **Stage 1 — Review**: Each checklist item evaluated against the subject
- [ ] **Stage 1 — Review**: Findings classified by severity per the rubric
- [ ] **READ-ONLY enforced**: Subject artifact NOT modified at any point during review
- [ ] **Stage 2 — Output**: Findings written to `$PROJECT_DIR/logs/{skill-name}/findings-{YYYYMMDD-HHMMSS}.yaml`
- [ ] **Stage 2 — Verdict**: Aggregate verdict computed (PASS / FAIL / CONDITIONAL — per skill's specific rubric)
- [ ] **Diagnostics**: Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`
- [ ] **Findings + verdict presented to user**

---

## Workflow

### Stage 0: Pre-Flight

```
├── Verify subject artifact(s) exist and are readable
├── Load references/{checklist}.md
├── Load references/{severity-rubric}.md
└── Load templates/findings-output.yaml
```

### Stage 1: Review

For each checklist item:

```
1. Read the relevant section of the subject artifact
2. Evaluate against the checklist criterion
3. If finding identified:
   ├── Classify severity per the rubric
   ├── Capture location (file:line or section reference)
   └── Write rationale (1-3 sentences)
```

### Stage 2: Output + Verdict

```
├── Aggregate findings by severity
├── Compute verdict per the skill's rubric
├── Write findings to $PROJECT_DIR/logs/{skill-name}/
└── Present summary to user
```

### Stage 3: Diagnostics (REQUIRED)

Write to `$PROJECT_DIR/logs/diagnostics/{skill-name}-{YYYYMMDD-HHMMSS}.yaml`

---

## Severity Rubric (Reference)

Reference the full rubric in `references/{severity-rubric}.md`. Standard tiers:

| Severity | Definition |
|----------|------------|
| **CRITICAL** | Must be addressed before {action — e.g., merge, deploy, ship} |
| **HIGH** | Should be addressed soon; blocks higher-quality outcomes |
| **MEDIUM** | Worth addressing; not blocking |
| **LOW** | Nice-to-have; cosmetic or minor improvements |

Do NOT invent severities. Each finding maps to exactly one tier.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Subject artifact not found | Report path; STOP |
| Checklist file missing | Report; STOP — cannot review without checklist |
| Subject artifact is malformed (parse error) | Report parse error; do NOT proceed with review on malformed input |
| Modification accidentally made | Revert immediately; report violation; STOP |
```

## Common Sub-Patterns

Reviewer skills exhibit several recurring sub-patterns. Sub-patterns are additive — pick those that apply.

### `standalone`

**Definition**: Reviewer is invoked directly by the user as a primary action.

**When to use**: The review is the user's goal — they're auditing something specifically.

**Bulwark example**: `code-review`, `mock-detection`, `bulwark-standards-reviewer` (when invoked directly).

**How it shapes the skill**:
- User-facing CLI/skill invocation.
- Verdict is presented prominently.
- Output is a deliverable — write to `$PROJECT_DIR/artifacts/{skill-name}/{slug}/findings.yaml`, NOT just to logs.

### `pipeline-stage`

**Definition**: Reviewer operates as a single stage within a larger orchestrating Pipeline skill.

**When to use**: The review is one step in a multi-stage workflow (audit → fix → re-audit, or scan → classify → report).

**Bulwark example**: `test-classification` runs as a stage of `test-audit`; `plan-creation-qa-critic` runs as the final stage of `plan-creation`.

**How it shapes the skill**:
- Output goes to `$PROJECT_DIR/logs/{orchestrator}/` so the next stage can read it.
- Verdict format is structured for downstream consumption (machine-readable YAML).
- The skill description includes "Pipeline stage" and identifies the orchestrator.
- DO NOT present output directly to the user — that's the orchestrator's job.

### `multi-source`

**Definition**: Reviewer reads multiple prior artifacts (logs, prior-stage outputs, external context) and synthesizes a verdict ACROSS all of them.

**When to use**: The review's value is the cross-artifact analysis (gap detection, consistency check, holistic verdict).

**Bulwark example**: `product-ideation-strategist` reads all 5 prior pipeline logs and applies BUY/HOLD/SELL framework; `plan-creation-qa-critic` adversarially reviews all prior-stage outputs.

**How it shapes the skill**:
- Pre-Flight stage explicitly loads ALL inputs (not lazy).
- Findings include cross-references between sources (e.g., "F-007: Architecture report claims X, but Eng Lead estimate assumes Y").
- Verdict reflects holistic judgment, not per-source pass/fail.

---

## Generated Findings Template

```yaml
# templates/findings-output.yaml
metadata:
  reviewer: {skill-name}
  subject: {path-to-subject}
  timestamp: {ISO-8601}
  duration_ms: {execution-time}

verdict: {PASS | CONDITIONAL | FAIL}  # Or skill-specific verdicts (BUY/HOLD/SELL, APPROVE/MODIFY/REJECT)

findings:
  - id: F-001
    severity: {CRITICAL | HIGH | MEDIUM | LOW}
    location: {file:line or section}
    description: {1-3 sentences}
    rationale: {why this matters}
    rule: {checklist item reference}
    suggested_fix: {optional — what would resolve this}

summary:
  total_findings: {count}
  critical: {count}
  high: {count}
  medium: {count}
  low: {count}
```

## Guidance for Generator

- Reviewers MUST be read-only. SKILL.md should explicitly state "this skill does NOT modify the subject" in the When to Use section.
- Findings format MUST be severity-classified per a documented rubric. Do NOT allow ad-hoc severities.
- Verdict format MUST be defined upfront (PASS/FAIL, BUY/HOLD/SELL, APPROVE/MODIFY/REJECT) so users can predict the output shape.
- Sub-pattern selection is critical: `standalone` skills present verdicts to the user; `pipeline-stage` skills format output for the next stage; `multi-source` skills load all inputs upfront.
- Reference Bulwark's existing reviewers as canonical examples: `code-review`, `mock-detection`, `bulwark-standards-reviewer`.
- Reviewers typically 150-250 lines for SKILL.md plus the checklist + rubric references.
- If the skill needs to ALSO fix what it reviews, it's NOT a Reviewer — it's a Pipeline (review → fix as separate stages, possibly orchestrated together).
- For agents (not skills), the Reviewer pattern is the most common shape — see `agent-template.md` for the agent-specific structure.
