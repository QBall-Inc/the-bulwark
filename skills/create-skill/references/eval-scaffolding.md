# Eval Scaffolding — Layer 1 DATA Per-Archetype Emission

**Purpose**: Tells the Stage 2 generator sub-agent what to write into the new skill's `evals/` directory. Schema is locked in `references/eval-shape.md`; this file is the per-archetype emission guide.

**Read this when**:
- Generating a new skill (Stage 2) — load alongside the matching `template-{archetype}.md`
- Retrofitting evals onto an existing skill (P9.1 / P9.2)
- Reviewing a generated skill's `evals/` for archetype shape correctness

---

## What Gets Scaffolded

Every generated skill receives:

| File | When | Purpose |
|------|------|---------|
| `evals/evals.json` | Always | Behavioral test prompts + assertions |
| `evals/triggers.json` | Always | Should-trigger / should-not-trigger queries (Anthropic 20-query format) |
| `evals/compliance.json` | Subjective archetypes only (Research, Inversion) — or any archetype overridden to `subjective` at Stage 1 | Log/artifact-based stage-execution checks |

**Schema source of truth**: `references/eval-shape.md`. Read it first if you are unfamiliar with the field shapes.

---

## Default `grading_mode` Per Archetype

Set in Stage 1 classification. Author may override per-test in `evals.json`.

| Archetype | Default `grading_mode` | Rationale |
|-----------|------------------------|-----------|
| Generator | `objective` | Output is on-disk artifacts — deterministic file/content checks |
| Tool Wrapper | `objective` | Loaded as reference — trigger reliability + content load checks suffice |
| Pipeline | `objective` | Stage execution observable via `tool_use_called(Task)`; synthesis quality optional `fuzzy` |
| Reviewer | `objective` | Verdict format + finding shape are deterministic; precision/recall via prompt fixtures |
| Script-driven | `objective` | Script output deterministic; `regex_match` + `exit_code` cover most cases |
| Research | `subjective` | Synthesis quality is judgment-laden; deterministic stage execution + `fuzzy` quality assertions |
| Inversion | `subjective` | Interview-driven — `compliance.json` verifies AskUserQuestion calls; `fuzzy` assesses output fitness |

**Rule**: Sub-patterns NEVER flip an archetype's default `grading_mode`. They add assertion templates within the existing mode (Model A locked at S109 startup).

---

## Placeholder Substitution Guide

When emitting `evals/*.json`, substitute these markers with values from the classification + interview state:

| Marker | Source | Example |
|--------|--------|---------|
| `<<SKILL_NAME>>` | Stage 1 classification | `slug-from-title` |
| `<<SKILL_PATH>>` | Target deployment path | `skills/slug-from-title` |
| `<<SKILL_VERSION>>` | Default `1.0.0` for new skills | `1.0.0` |
| `<<GRADING_MODE>>` | Archetype default (table above) | `objective` |
| `<<INVOCATION_EXAMPLE_1>>` | Q1 interview answer (concrete invocation example #1) | `Create a slug from "My Article Title"` |
| `<<INVOCATION_EXAMPLE_2>>` | Q1 interview answer #2 | `Generate a slug for blog post X` |
| `<<TRIGGER_QUERY_POSITIVE_1..N>>` | Derived from Q1 — positive trigger phrasings | `slugify this title` |
| `<<TRIGGER_QUERY_NEGATIVE_1..N>>` | Generic non-triggers + similar-but-different intents | `What does this code do?` |
| `<<STAGE_ID_N>>` / `<<STAGE_DESCRIPTION_N>>` | SKILL.md pipeline stages (subjective only) | `stage_2_generate` |

**Substitute literally — no templating engine.** The orchestrator is Claude; it reads JSON examples below and writes substituted JSON via the Write tool.

**Seed at least one concrete test** from interview answers. Mark TBD slots with comments **outside** the JSON or by leaving placeholder strings the user must replace post-scaffold (e.g., `"prompt": "<<TODO: add second test prompt>>"`). Generated skills are starter kits — explicit TODOs > silent gaps.

---

## Per-Archetype Emission Templates

Each archetype below shows the minimum-viable `evals.json` shape. The generator emits ONE concrete starter test (seeded from Q1) plus a placeholder for adding more. `triggers.json` follows the same shape across archetypes (10 should-trigger + 10 should-not-trigger). `compliance.json` ships only for subjective archetypes.

### Generator

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "objective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — generates expected artifact from realistic input",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Write", "Edit", "Glob"],
      "timeout_seconds": 300,
      "assertions": [
        {
          "type": "tool_use_called",
          "tool": "Write",
          "min_count": 1
        },
        {
          "type": "file_written",
          "path_glob": "<<EXPECTED_OUTPUT_GLOB>>",
          "min_count": 1
        },
        {
          "type": "exit_code",
          "value": 0
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `multi-template` → add one `file_written` assertion per template variant; consider one test per template
- `configuration-emitting` → use `content_contains` to assert config block written into target file (vs. file creation)
- `interview-augmented` → seed prompt with the Q-A flow; assert `tool_use_called(AskUserQuestion)` + final `file_written`

### Tool Wrapper

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "objective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — content loads when triggered",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Glob"],
      "timeout_seconds": 180,
      "assertions": [
        {
          "type": "stream_event_emitted",
          "event_type": "system",
          "subtype": "init",
          "field_check": {
            "plugin_errors_empty": true
          }
        },
        {
          "type": "regex_match",
          "target": "all_assistant_text",
          "pattern": "<<EXPECTED_CONCEPT_FROM_REFERENCE>>",
          "case_insensitive": true
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `context-injected` → add `tool_use_called` assertion for the hook-loaded context (e.g., `Read` of bundled reference file)
- `schema-convention` → assert that downstream output conforms to the schema (regex or content_contains on schema-required fields)
- `methodology` / `pattern-catalog` → fuzzy-grade rare; concept-presence regex usually adequate
- `curated-data-library` → assert `Read` of bundled `data/*.json|yaml|md`

### Pipeline

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "objective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — pipeline orchestrates expected sub-agents",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Write", "Edit", "Task", "Glob", "Grep"],
      "timeout_seconds": 600,
      "assertions": [
        {
          "type": "tool_use_called",
          "tool": "Task",
          "min_count": 1
        },
        {
          "type": "file_written",
          "path_glob": "<<EXPECTED_PIPELINE_OUTPUT_GLOB>>",
          "min_count": 1
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `reviewer-orchestrating` → add `tool_use_called(Task, name_matches="<reviewer-agent-name>")`
- `research-orchestrating` → assert ≥3 parallel `Task` calls (`min_count: 3` for research-style branching)
- `generator-orchestrating` → assert final-stage `Write` to expected artifact path

If the author wants synthesis-quality grading, override `grading_mode` to `subjective` and add `fuzzy` assertions.

### Reviewer

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "objective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — reviewer detects expected violation in fixture",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Write", "Glob", "Grep"],
      "timeout_seconds": 300,
      "assertions": [
        {
          "type": "file_written",
          "path_glob": "logs/<<SKILL_NAME>>-*.{md,yaml}",
          "min_count": 1
        },
        {
          "type": "regex_match",
          "target": "result",
          "pattern": "(critical|high|medium|low|pass|fail)",
          "case_insensitive": true
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `standalone` → assert no `Task` calls (`max_count: 0`) — runs in main loop
- `pipeline-stage` → assert subagent invocation pattern (input-from-prior-stage path read)
- `multi-source` → assert ≥N `Read` calls covering distinct artifact types

For deterministic fixture-based testing, ship a known-violation fixture under `evals/fixtures/` and seed the prompt to point at it.

### Script-driven

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "objective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — wraps and executes bundled script",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Bash"],
      "timeout_seconds": 180,
      "assertions": [
        {
          "type": "tool_use_called",
          "tool": "Bash",
          "min_count": 1,
          "name_matches": "<<EXPECTED_SCRIPT_INVOCATION_REGEX>>"
        },
        {
          "type": "regex_match",
          "target": "result",
          "pattern": "<<EXPECTED_OUTPUT_PATTERN>>"
        },
        {
          "type": "exit_code",
          "value": 0
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `hook-orchestrated` → set `user-invocable: false` in skill frontmatter (asserted at scaffold time, not runtime); the eval test invokes via the script directly with `claude -p`

### Research (subjective)

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "subjective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — multi-viewpoint synthesis on representative topic",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Write", "Task", "WebSearch", "WebFetch"],
      "timeout_seconds": 900,
      "assertions": [
        {
          "type": "tool_use_called",
          "tool": "Task",
          "min_count": 3
        },
        {
          "type": "file_written",
          "path_glob": "<<SYNTHESIS_OUTPUT_GLOB>>",
          "min_count": 1
        },
        {
          "type": "fuzzy",
          "description": "Synthesis covers required perspectives without bias",
          "evidence_paths": ["<<SYNTHESIS_OUTPUT_GLOB>>"],
          "rubric": "Synthesis cites multiple distinct viewpoints; no perspective omitted; sources tiered (T1/T2/T3) when applicable"
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `reviewer-validated` (default ON) → ALSO emit `compliance.json` stage check for the validation gate (see compliance.json template below); add `fuzzy` rubric line: "Critical Evaluation Gate fired and findings logged"
- `source-tier-disciplined` → fuzzy rubric explicitly checks T1/T2/T3 source classification

### Inversion (subjective)

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "grading_mode": "subjective",
  "tests": [
    {
      "id": "T1",
      "description": "Starter test — interview-driven generation produces fit artifact",
      "prompt": "<<INVOCATION_EXAMPLE_1>>",
      "allowed_tools": ["Read", "Write", "Edit", "AskUserQuestion"],
      "timeout_seconds": 600,
      "assertions": [
        {
          "type": "tool_use_called",
          "tool": "AskUserQuestion",
          "min_count": 1
        },
        {
          "type": "file_written",
          "path_glob": "<<EXPECTED_OUTPUT_GLOB>>",
          "min_count": 1
        },
        {
          "type": "fuzzy",
          "description": "Generated artifact matches stated interview answers",
          "evidence_paths": ["<<EXPECTED_OUTPUT_GLOB>>"],
          "rubric": "Output reflects interview answers literally where applicable; no contradictions between answer and artifact"
        }
      ]
    }
  ]
}
```

**Sub-pattern additions**:
- `generator-coupled` (canonical) → already implicit; ensure final-stage `file_written` matches the coupled generator's output shape

---

## triggers.json (All Archetypes — Same Shape)

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "should_trigger": [
    { "query": "<<TRIGGER_QUERY_POSITIVE_1>>", "reasoning": "Direct invocation phrasing" },
    { "query": "<<TRIGGER_QUERY_POSITIVE_2>>", "reasoning": "Synonym phrasing" },
    { "query": "<<TRIGGER_QUERY_POSITIVE_3>>", "reasoning": "Indirect-but-clear request" },
    { "query": "<<TRIGGER_QUERY_POSITIVE_4>>", "reasoning": "<<TODO: add reasoning>>" },
    { "query": "<<TRIGGER_QUERY_POSITIVE_5>>", "reasoning": "<<TODO: add reasoning>>" },
    { "query": "<<TODO: add 5 more should-trigger queries>>", "reasoning": "" }
  ],
  "should_not_trigger": [
    { "query": "<<TRIGGER_QUERY_NEGATIVE_1>>", "reasoning": "Read-only question" },
    { "query": "<<TRIGGER_QUERY_NEGATIVE_2>>", "reasoning": "Adjacent-but-distinct intent" },
    { "query": "<<TRIGGER_QUERY_NEGATIVE_3>>", "reasoning": "<<TODO: add reasoning>>" },
    { "query": "<<TODO: add 7 more should-not-trigger queries>>", "reasoning": "" }
  ]
}
```

Seed 3-5 entries from Q1 interview answers + adjacent-intent queries. Mark the remainder with explicit `<<TODO>>` placeholders so the user knows what to fill in. Pass criterion: ≥80% of `should_trigger` triggered AND ≥80% of `should_not_trigger` did NOT trigger.

---

## compliance.json (Subjective Only — Research, Inversion, or Subjective Override)

Stage execution checks. Map each declared SKILL.md pipeline stage to deterministic evidence (file_written, tool_use_called) where possible. Use `fuzzy` only when no deterministic check fits.

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "<<SKILL_PATH>>",
  "skill_version": "<<SKILL_VERSION>>",
  "stages": [
    {
      "stage_id": "<<STAGE_ID_1>>",
      "description": "<<STAGE_DESCRIPTION_1>>",
      "expected_evidence": [
        {
          "type": "tool_use_called",
          "tool": "AskUserQuestion",
          "min_count": 1
        }
      ],
      "min_evidence_matches": 1
    },
    {
      "stage_id": "<<STAGE_ID_2>>",
      "description": "<<STAGE_DESCRIPTION_2>>",
      "expected_evidence": [
        {
          "type": "tool_use_called",
          "tool": "Task",
          "min_count": 1
        }
      ],
      "min_evidence_matches": 1
    },
    {
      "stage_id": "<<TODO: add stage check>>",
      "description": "",
      "expected_evidence": [],
      "min_evidence_matches": 1
    }
  ]
}
```

**Stage-IDs**: derive from the SKILL.md pipeline. Naming convention: `stage_<N>_<verb>` (e.g., `stage_1_classify`, `stage_2_generate`, `stage_3_validate`). Each stage_id must match the actual stage number in the generated SKILL.md.

**Memo D3 hard constraint**: stage evidence must be deterministic (`tool_use_called`, `file_written`, `stream_event_emitted`) wherever possible. Reserve `fuzzy` for stages whose execution genuinely cannot be expressed as a tool/file pattern.

---

## Sub-Pattern × Eval Impact (Quick Reference)

| Archetype | Sub-Pattern | Eval Impact |
|-----------|-------------|-------------|
| Generator | `multi-template` | One test per template variant; `file_written` per output path |
| Generator | `configuration-emitting` | `content_contains` on injected config block |
| Generator | `interview-augmented` | Seed prompt with Q-A flow; assert `tool_use_called(AskUserQuestion)` |
| Tool Wrapper | `context-injected` | Assert hook-loaded `Read` of bundled reference |
| Tool Wrapper | `schema-convention` | Schema-conformance regex on downstream output |
| Tool Wrapper | `methodology` | Concept-presence `regex_match` on output text (rare to fuzzy-grade) |
| Tool Wrapper | `pattern-catalog` | `regex_match` on named-pattern reference in output (e.g., catalog entries cited) |
| Tool Wrapper | `curated-data-library` | Assert `Read` of bundled `data/*` |
| Pipeline | `reviewer-orchestrating` | `tool_use_called(Task, name_matches="<reviewer>")` |
| Pipeline | `research-orchestrating` | `tool_use_called(Task, min_count: 3)` (parallel branching) |
| Pipeline | `generator-orchestrating` | `file_written` on final-stage artifact |
| Research | `reviewer-validated` (default ON) | Compliance stage check for validation gate firing |
| Research | `source-tier-disciplined` | Fuzzy rubric checks T1/T2/T3 source classification |
| Reviewer | `standalone` | `tool_use_called(Task, max_count: 0)` |
| Reviewer | `pipeline-stage` | Input-from-prior-stage path `Read` |
| Reviewer | `multi-source` | ≥N distinct `Read` calls |
| Script-driven | `hook-orchestrated` | `user-invocable: false` (frontmatter check, not runtime); test invokes script directly |
| Inversion | `generator-coupled` (canonical) | Already implicit; ensure final-stage `file_written` matches coupled generator |

---

## Cross-References

- `references/eval-shape.md` — Schema source of truth for `evals.json` / `triggers.json` / `compliance.json`
- `references/decision-framework.md` — Archetype + sub-pattern selection (Stage 1)
- `references/template-{archetype}.md` — Per-archetype skill body shape
- `scripts/run-loop.ts` — Reads scaffolded `evals.json` + `triggers.json` + `compliance.json`
- `scripts/grade.ts` — Grades the run; emits `grading-<ts>.json` + Markdown report
- `agents/skill-eval-grader.md` — Invoked for `fuzzy` assertions (artifact-based per memo D3)
- `docs/internal/p10.2-part-b-scope-decision.md` — Memo D3 (artifact-grading constraint), Memo D11 (cross-file consistency)
