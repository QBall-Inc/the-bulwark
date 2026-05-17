# Template: Inversion Skill (Interview-Driven Authoring)

Use this template when the skill produces a new artifact through staged user interrogation. Unlike Generators (which take inputs and emit), Inversion skills CONDUCT THE INTERVIEW that elicits inputs as their primary structural shape.

**When to use**: The user can't reasonably specify all inputs upfront via CLI args or a single prompt. The skill's primary value is the structured conversation that drafts the artifact. Per memo D4, Inversion is a STANDALONE archetype — not a composable modifier.

---

## File Structure

```
skills/{skill-name}/
├── SKILL.md
├── references/
│   ├── interview-questions.md   # The question bank
│   ├── decision-tree.md         # Routing logic for adaptive follow-ups
│   └── {output-format}.md       # Spec for the artifact being authored
└── templates/
    └── {artifact-template}.md   # Final artifact template (filled by interview answers)
```

## Generated SKILL.md Structure

```markdown
---
name: {skill-name}
description: {single-line, trigger-specific, "Use when..." framing}
user-invocable: true
argument-hint: "[<topic or initial input>]"
version: 1.0.0
author: "Ashay Kubal @ Qball Inc."
---

# {Skill Title}

{One-paragraph summary: what artifact is authored, why interview is needed (vs. CLI args), what the interview elicits.}

---

## When to Use This Skill

{Trigger pattern table + DO NOT use for section.}

**Inversion vs Generator**: Use this skill when the user genuinely needs help SPECIFYING the inputs. If the user already knows exactly what they want and just needs the artifact emitted, prefer a Generator skill (CLI args + template fill).

**Escape hatch**: This skill should support `--from-template <preset>` (or equivalent) to skip the interview and use a known preset, for users who already know what they want.

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Interview questions** | `references/interview-questions.md` | **REQUIRED** | Load at Stage 0 |
| **Decision tree** | `references/decision-tree.md` | **REQUIRED** | Load at Stage 0; consult after each round |
| **Output format spec** | `references/{output-format}.md` | **REQUIRED** | Load before generation stage |
| **Artifact template** | `templates/{artifact-template}.md` | **REQUIRED** | Fill at generation stage |

---

## Usage

```
/{skill-name} [<initial-topic>]
/{skill-name} --from-template <preset>  # Skip interview, use preset
```

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill is interview-driven. The interview MUST happen before generation; generation MUST NOT proceed on incomplete answers. Follow every item in order. Do NOT return to the user until all applicable items are checked.

- [ ] **Stage 0 — Pre-Flight**: All required references and templates loaded
- [ ] **Stage 0 — Mode Check**: If `--from-template` flag passed, skip Stages 1-2 and use preset
- [ ] **Stage 1 — Interview Round 1**: AskUserQuestion conducted with the core question set
- [ ] **Stage 1 — Decision Tree**: User answers routed through decision tree to determine follow-up rounds
- [ ] **Stage 2 — Follow-Up Rounds**: AskUserQuestion conducted for adaptive follow-ups (0-N additional rounds)
- [ ] **Stage 2 — Completeness Check**: All required slots have answers; ambiguous answers re-asked at most ONCE
- [ ] **Stage 3 — Generate**: Artifact template filled with interview answers
- [ ] **Stage 3 — Validate**: Generated artifact has correct structure (frontmatter, required sections, valid syntax)
- [ ] **Stage 4 — Write**: Artifact written to the prescribed output path
- [ ] **Stage 5 — Diagnostics**: Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`
- [ ] **Result presented to user** (output path + summary; user can revise via additional rounds)

---

## Pipeline

```fsharp
// {skill-name} pipeline
Stage0_PreFlight()
|> (if --from-template then Stage3_Generate(preset) else continue)
|> Stage1_Interview_Round1(core_questions)
|> Stage1_DecisionTree(answers)             // Routes to follow-ups
|> Stage2_Interview_Followups(routed_qs)    // 0-N additional rounds
|> Stage2_Completeness(all_answers)
|> Stage3_Generate(answers + template)
|> Stage4_Validate_Write(artifact)
|> Diagnostics()
```

---

## Stage Definitions

### Stage 0: Pre-Flight

```
├── Load references/interview-questions.md
├── Load references/decision-tree.md
├── Load references/{output-format}.md
├── Load templates/{artifact-template}.md
├── Initialize answer slots
└── Check for --from-template flag (if passed, jump to Stage 3 with preset answers)
```

### Stage 1: Interview Round 1 (Core Questions)

Use AskUserQuestion to ask the core question set. Each question:

```
- header: {3-12 char tab name}
- question: {clear, single-sentence question}
- multiSelect: {true | false}
- options: {3-4 predefined options when applicable; one option labeled "Other (specify)"}
```

Read `references/interview-questions.md` for the canonical core set.

### Stage 1: Decision Tree

After core answers, consult `references/decision-tree.md` to route to follow-up rounds:

```
IF answer_to_Q1 == X AND answer_to_Q3 == Y:
  follow_up_rounds = [round_A, round_B]
ELIF answer_to_Q1 == Z:
  follow_up_rounds = [round_C]
ELSE:
  follow_up_rounds = []
```

### Stage 2: Follow-Up Rounds (Adaptive)

For each routed follow-up round, conduct another AskUserQuestion call. Each round should:
- Be triggered by specific answers (not always asked)
- Have 1-3 questions per round
- Remain focused on disambiguation, NOT over-elicitation

**Hard cap: 4 rounds total.** Beyond 4 rounds signals that the skill should be re-shaped — either reduce the question set, or split into multiple narrower skills.

### Stage 2: Completeness Check

After all rounds:
- Verify every required slot has an answer
- For ambiguous answers, ask ONE clarifying question (do NOT interview indefinitely)
- If still ambiguous, document the gap, proceed with best-guess, and note the ambiguity in the output

### Stage 3: Generate

Fill the artifact template with answers. Validate structure. Do NOT write yet.

### Stage 4: Validate + Write

```
├── Validate generated artifact (frontmatter present, sections complete, syntax valid)
├── If validation fails: report error, do NOT write
├── Write to output path
└── Present to user (path + summary)
```

### Stage 5: Diagnostics

Write to `$PROJECT_DIR/logs/diagnostics/{skill-name}-{YYYYMMDD-HHMMSS}.yaml`

Include: number of rounds conducted, slots filled, ambiguities recorded, mode (interview vs from-template).

---

## Error Handling

| Scenario | Action |
|----------|--------|
| User aborts interview mid-flow | Save partial answers to logs/; offer resumption on next invocation |
| Required slot has no answer after follow-ups | Document gap; proceed with placeholder + WARNING in output |
| Generated artifact fails validation | Report error; do NOT write; offer to re-interview the relevant slot |
| User wants to revise after generation | Re-enter at Stage 2 (additional rounds) for the slots being revised |
| `--from-template` preset not found | Report available presets; STOP |
```

## Common Sub-Patterns

Inversion skills typically exhibit one canonical sub-pattern.

### `generator-coupled`

**Definition**: The interview's purpose is to elicit inputs for a Generator-style template fill. The skill is structurally Inversion + Generator combined: interview elicits inputs; Stage 3 fills a template.

**When to use**: This is the dominant Inversion shape. Most interview-driven skills generate something at the end.

**Bulwark example**: `create-skill` interviews about archetype/sub-patterns/triggers, then fills a SKILL.md template; `create-subagent` interviews about identity/mission, then fills an agent template.

**How it shapes the skill**:
- Stage 3 (Generate) borrows the Generator archetype's template-fill mechanism — see `template-generator.md` for the validation pattern.
- Templates live in `templates/` with explicit placeholders (`{NAME}`, `__NAME__`, etc.).
- Validation in Stage 4 follows the Generator's "validate before write" pattern.
- The escape hatch (`--from-template`) is a Generator-only mode of the skill — bypasses interview, takes inputs directly.

---

## Generated Reference Structures

### references/interview-questions.md

```markdown
# Interview Questions: {Skill Name}

## Core Question Set (Round 1 — always asked)

### Q1: {Single-sentence question}

- header: {Tab name}
- multiSelect: false
- options:
  - {Option 1}
  - {Option 2}
  - Other (specify)

{Repeat for Q2, Q3, ...}

## Follow-Up Rounds

### Round A: {Trigger condition}

{Same structure as core questions; only asked when triggered.}

### Round B: ...
```

### references/decision-tree.md

```markdown
# Decision Tree: {Skill Name}

After Round 1 answers, route to follow-up rounds:

| Q1 Answer | Q2 Answer | Q3 Answer | Follow-Up Rounds |
|-----------|-----------|-----------|------------------|
| X | * | * | A |
| Y | A | * | B, C |
| Y | B | * | C |
| Z | * | * | (none) |

(Document the conditional logic so anyone can audit it.)
```

## Guidance for Generator

- Inversion is the rare archetype where the INTERVIEW is the primary deliverable shape, not the artifact emitted at the end.
- Use AskUserQuestion liberally but bounded — 4 rounds maximum. More than that signals the user should pre-specify in CLI args (Generator) or use a different skill.
- Decision tree is the heart of the skill — without routing logic, every interview asks every question (wasteful and confusing).
- Reference both `interview-questions.md` AND `decision-tree.md` from SKILL.md.
- Provide ONE escape hatch: `--from-template <preset>` flag (or equivalent) for users who want to skip the interview and use a known preset. This is the Generator "back door" of an Inversion skill.
- Inversion skills typically 200-350 lines for SKILL.md plus the question bank + decision tree + artifact template.
- See `create-skill` and `create-subagent` for canonical examples of Inversion skills in Bulwark.
- Inversion is STANDALONE per memo D4 — not a composable modifier on top of other archetypes. If you find yourself wanting "interview-modified Pipeline", that's a Pipeline with an interview Stage 0 (which is Pipeline shape, not Inversion).
