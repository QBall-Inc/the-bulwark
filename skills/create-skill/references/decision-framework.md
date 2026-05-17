# Decision Framework

Interview questions and classification logic for the create-skill pipeline. The orchestrator uses this at Stage 0 (Pre-Flight) and Stage 1 (Classify).

The framework outputs five things:

1. **Primary archetype** (one of 7) — drives the template selection.
2. **Candidate sub-patterns** (0-N from the chosen archetype's catalog) — additive guidance feeding the generator.
3. **Context mode** (inline or fork) — orthogonal to archetype.
4. **Default `grading_mode`** (objective or subjective) — derives from archetype; drives evals/ scaffolding shape per `references/eval-scaffolding.md`. Author may override at Stage 1 confirmation.
5. **`bundles_scripts`** (true/false) — true canonically for Script-driven; ask follow-up for non-Script-driven archetypes. Drives `scripts/` directory scaffolding per `references/scripts-conventions.md`.

Path A is in effect (per memo D2 + Part F decisions): sub-patterns are documented additive guidance per archetype, NOT matrix-scored composition. Matrix scoring (Path B) is deferred to potential v1.3.

Sub-patterns NEVER flip an archetype's default `grading_mode` (Model A locked at S109 startup) — they add assertion templates within the existing mode. See `references/eval-scaffolding.md` → Sub-Pattern × Eval Impact for additive customizations.

---

## Stage 0: Adaptive Interview

### Core Question Set

Present these via a single AskUserQuestion call. Answers map deterministically to archetype.

| # | Question | Purpose |
|---|----------|---------|
| Q1 | What does this skill do? Give 2-3 concrete examples of how someone would invoke it. | Triggers + scope |
| Q2 | What is the skill's primary action? (Choose the dominant one — even if multiple apply, one shape dominates.) | Primary archetype routing |
| Q3 | If creating a new artifact: does it collect inputs from CLI/state/prior-output, or interview the user via AskUserQuestion? | Generator vs Inversion disambiguation |
| Q4 | If orchestrating: are stages sequential (each depends on prior output) or parallel viewpoints (multi-source synthesis)? | Pipeline vs Research disambiguation |
| Q5 | Does it need conversation history, or can it run in complete isolation? | Context mode (inline vs fork) |

### Q2 Options (Primary Action)

Present these options when asking Q2:

| Option | Routes To |
|--------|-----------|
| **Audit / score existing artifacts** (code, tests, docs, plans) — produces severity-classified findings | Reviewer |
| **Create new artifacts** (files, configs, blocks of text) — output is something new on disk | Generator or Inversion (Q3 disambiguates) |
| **Document conventions / patterns / methodology** — content is loaded by other skills as reference | Tool Wrapper |
| **Orchestrate multiple agents or stages** — coordinates work across sub-agents | Pipeline or Research (Q4 disambiguates) |
| **Wrap an external script or binary** — primary value is the bundled script's execution | Script-driven |

### Follow-Up Questions (Conditional, Round 2)

Ask follow-ups to disambiguate sub-patterns within the chosen archetype. Only ask the relevant follow-up — do NOT present all of them.

| Trigger | Follow-Up |
|---------|-----------|
| Q2 = Audit/score | Q6: Is this a standalone audit (user-invoked), a pipeline stage, or a multi-source review (reads several prior artifacts)? |
| Q2 = Create + Q3 = CLI/state | Q7: Single template, multi-template (picks based on input), or config-block injection (writes into existing file)? |
| Q2 = Document | Q8: Context-injected (loaded via SessionStart hook) / schema-convention (defines a contract) / methodology (how-to reference) / pattern-catalog (named patterns) / curated-data-library (bundled data)? |
| Q2 = Orchestrate + Q4 = sequential | Q9: Are constituent stages predominantly Reviewer-shaped, Research-shaped, or Generator-shaped? (Affects sub-pattern.) |
| Q2 = Orchestrate + Q4 = parallel | Q10: Should the skill embed a Reviewer-validated gate (Critical Evaluation Gate)? Recommended ON by default. |
| Q2 = Wrap script | Q11: Is the script invoked by a Claude Code hook (statusLine, SessionStart, PostToolUse)? |
| Q2 = Create + Q3 = interview | (None — Inversion's `generator-coupled` sub-pattern is canonical) |

### Interview Behavior

- Present Q1-Q5 in a single AskUserQuestion call (not one-at-a-time).
- Round 2 follow-ups (if needed) target sub-pattern disambiguation.
- Total interview: 1-2 AskUserQuestion rounds maximum.
- If a `--doc` requirements document is provided, extract Q1-Q5 answers from it and present for confirmation rather than asking fresh.

---

## Stage 1: Archetype Classification

After the interview, classify the skill into one of 7 archetypes.

### Decision Tree → Primary Archetype

```
Q2 = Audit/score                       → Reviewer
Q2 = Document conventions              → Tool Wrapper
Q2 = Wrap external script              → Script-driven
Q2 = Create new artifact
  AND Q3 = CLI/state inputs            → Generator
  AND Q3 = AskUserQuestion-driven      → Inversion
Q2 = Orchestrate
  AND Q4 = sequential stages           → Pipeline
  AND Q4 = parallel viewpoints + synth → Research
```

### Archetype → Template Mapping

| Archetype | Template | File Structure |
|-----------|----------|----------------|
| Generator | `template-generator.md` | `SKILL.md` + `templates/` |
| Tool Wrapper | `template-tool-wrapper.md` | `SKILL.md` + `references/` (+ optional `data/`) |
| Pipeline | `template-pipeline.md` | `SKILL.md` + `references/` + `templates/` + `.claude/agents/{skill-name}-{stage}.md` |
| Research | `template-research.md` | `SKILL.md` + `references/` + `templates/` |
| Script-driven | `template-script-driven.md` | `SKILL.md` + `scripts/` + `references/` |
| Reviewer | `template-reviewer.md` | `SKILL.md` + `references/` + `templates/` |
| Inversion | `template-inversion.md` | `SKILL.md` + `references/` + `templates/` |

### Sub-Pattern Lookup

After primary archetype is determined, look up candidate sub-patterns. Each archetype's full sub-pattern set is documented in its template's `## Common Sub-Patterns` section; the aggregated catalog lives in `content-guidance.md` → `## Sub-Pattern Catalog`.

| Archetype | Candidate Sub-Patterns |
|-----------|------------------------|
| Generator | `multi-template`, `configuration-emitting`, `interview-augmented` |
| Tool Wrapper | `context-injected`, `schema-convention`, `methodology`, `pattern-catalog`, `curated-data-library` |
| Pipeline | `reviewer-orchestrating`, `research-orchestrating`, `generator-orchestrating` |
| Research | `reviewer-validated` (default ON), `source-tier-disciplined` |
| Script-driven | `hook-orchestrated` |
| Reviewer | `standalone`, `pipeline-stage`, `multi-source` |
| Inversion | `generator-coupled` (canonical — always applies) |

**Default-ON sub-patterns**: Research's `reviewer-validated` (per Anthropic faithfulness research) and Inversion's `generator-coupled` (canonical shape) are recommended by default. The user may opt out, but the framework should suggest them by default.

**Sub-patterns are additive, not exclusive.** A single skill MAY exhibit multiple sub-patterns (e.g., `bulwark-research` is `source-tier-disciplined` + `reviewer-validated`).

### Context Mode (Orthogonal to Archetype)

```
Q5 = "needs conversation history"      → inline (no fork)
Q5 = "isolation OK"
  AND Archetype = Pipeline OR Research → context: fork (recommended for orchestrators)
  AND Archetype = anything else        → inline (no fork)
```

**Default**: inline. Fork is rare — only ~2 of 28 Bulwark skills use it. Warn if user requests fork for a non-orchestrating archetype (Generator, Tool Wrapper, Reviewer, Inversion, Script-driven).

### Default `grading_mode` (Derives from Archetype)

```
Generator, Tool Wrapper, Pipeline, Reviewer, Script-driven  → objective (default)
Research, Inversion                                          → subjective (default)
```

| Archetype | Default | Why |
|-----------|---------|-----|
| Generator | objective | Output is on-disk artifact — deterministic file/content checks |
| Tool Wrapper | objective | Loaded as reference — trigger reliability + content load checks |
| Pipeline | objective | Stage execution observable via `tool_use_called(Task)`; synthesis quality optional |
| Reviewer | objective | Verdict format + finding shape are deterministic |
| Script-driven | objective | Script output deterministic; `regex_match` + `exit_code` |
| Research | subjective | Synthesis quality is judgment-laden |
| Inversion | subjective | Output fitness vs. interview answers requires judgment |

**Author override**: At the Stage 1 classification confirmation prompt, the author may override the default. Typical override: Pipeline → subjective when the pipeline produces a synthesis that needs quality grading. Otherwise rare.

The resolved `grading_mode` is passed to Stage 2 as a CONSTRAINT and shapes which eval files get scaffolded:

| `grading_mode` | Scaffolded Files |
|----------------|------------------|
| objective | `evals/evals.json` + `evals/triggers.json` |
| subjective | `evals/evals.json` + `evals/triggers.json` + `evals/compliance.json` |

### `bundles_scripts` (Derives from Archetype + Optional Follow-up)

```
Archetype = Script-driven                          → bundles_scripts = true (canonical)
Archetype ∈ {Generator, Tool Wrapper, Pipeline,
              Reviewer, Research, Inversion}      → ASK follow-up
                                                       → "Will this skill bundle executable scripts?
                                                          (TypeScript via bun, or shell scripts) [Yes/No]"
                                                       → default: false if user answers No or skips
```

| Archetype | Default | Follow-up Required |
|-----------|---------|--------------------|
| Script-driven | true | No (canonical) |
| Generator | false | Yes (rare — most generators just emit on-disk artifacts) |
| Tool Wrapper | false | Yes (rare unless bundling validation/hook scripts) |
| Pipeline | false | Yes (sometimes — e.g., create-skill itself bundles `run-loop.ts` + `grade.ts`) |
| Reviewer | false | Yes (sometimes — e.g., bundling a static-analysis script) |
| Research | false | Yes (rarely needed) |
| Inversion | false | Yes (rarely needed) |

**Trigger detection signals** in Q1 invocation examples that should pre-fill `bundles_scripts = true`:
- "wraps a script", "runs a check", "validates via", "bundles a CLI tool"
- "TypeScript script", "shell script", "bun script"
- "executable", "binary"

The resolved `bundles_scripts` is passed to Stage 2 as a CONSTRAINT and shapes the directory scaffold:

| `bundles_scripts` | Scaffolded |
|-------------------|------------|
| true | `scripts/.gitkeep` + SKILL.md `Runtime Prerequisites` (bun) + `Permissions Setup` sections |
| false | No `scripts/` directory |

When `bundles_scripts = true` AND archetype ∉ {Script-driven}, log "non-canonical scripts bundling" in diagnostics for review (this is a valid but unusual combination — useful for spotting archetype misclassification).

See `references/scripts-conventions.md` for invocation convention (`${CLAUDE_PLUGIN_ROOT}` pattern), Justfile recipe pattern, and runtime/permissions documentation.

---

## Classification Output

After classification, present to the user via AskUserQuestion:

```
Classification:
- Primary archetype: {archetype} — {one-line reason from Q2 answer}
- Template: {template-name}
- Context: {inline | fork} — {one-line reason}
- Default grading_mode: {objective | subjective} — {derives from archetype}
- Bundles scripts: {Yes | No} — {derives from archetype + Q1 signal | follow-up answer}

Candidate sub-patterns for {archetype} (review full definitions in content-guidance.md → Sub-Pattern Catalog):
  {sub-pattern 1}: {one-line definition}
  {sub-pattern 2}: {one-line definition}
  ...

Which sub-patterns apply to your skill? (Select 0-N — leave empty for none.)
[ ] {sub-pattern 1}
[ ] {sub-pattern 2}
...

Proceed with generation? [Yes / Adjust grading_mode / Adjust bundles_scripts / Adjust sub-patterns / Adjust]
```

User's selected sub-patterns + final grading_mode + bundles_scripts are passed to the Stage 2 generator as part of CONSTRAINTS — the generated skill MUST include the documented sub-pattern sections per the chosen template's `## Common Sub-Patterns` definitions, the eval scaffolding MUST follow the resolved grading_mode per `references/eval-scaffolding.md`, and (when `bundles_scripts = true`) the scripts/ scaffolding + invocation convention + Permissions Setup MUST follow `references/scripts-conventions.md`.

---

## Edge Cases

| Scenario | Resolution |
|----------|------------|
| Skill matches multiple archetypes (e.g., audits AND generates) | Pick the dominant shape. The secondary shape is often expressible as a sub-pattern of the dominant archetype (e.g., "audit + generate" is typically Pipeline with `reviewer-orchestrating` + `generator-orchestrating` sub-patterns). |
| User requests fork for non-orchestrating archetype | Warn: "Fork adds overhead with no benefit for non-orchestrating skills. Recommend inline." Allow override but note in diagnostics. |
| Skill type doesn't clearly map to one of 7 archetypes | Pick the closest match. Note the mismatch in post-generation summary. Flag for `existing-skills-archetype-mapping.md` review if the shape is genuinely novel. Per memo D1, hard ceiling at 7 in v1.2 — new archetypes require "structurally distinct shape, not new use case" justification. |
| User unsure about Q2 primary action | Re-read Q1 examples. If still unsure, present a 2-question disambiguation: "Does the user invoke this directly?" + "Is the output a new file or a verdict on an existing one?" |
| Q2 = "Create new artifact" but the user describes interrogation as the primary work | Route to Inversion (interrogation IS the primary shape) and confirm. |
| Conflicting Q2/Q3/Q4 answers | Ask one clarifying question to resolve. If still conflicting, default to the more conservative archetype (Reviewer/Tool Wrapper > Pipeline/Research). |
| Very large skill (>200 lines estimated) | Apply tiered enforcement per memo D8 (amended S107) — see content-guidance.md → SKILL.md Size Guidance. Tiers: 200 = Advisory (soft note), 500 = Strong-warn (loud warning), 600 = Hard-cap (Stage 2 STOP with refactor proposal). Suggest splitting into multiple skills or composing via sub-patterns BEFORE approaching the 200 advisory tier. |
| User wants to compose multiple archetypes (matrix-scoring style) | Path B not in v1.2 scope. Offer the dominant-archetype + sub-patterns approach, OR suggest splitting the work across multiple skills. |
