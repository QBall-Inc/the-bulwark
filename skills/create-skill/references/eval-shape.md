# Eval Shape — Layer 1 Data Schema

**Purpose**: Lock the JSON schemas that `create-skill` Stage 3 emits per generated skill (Layer 1) and that `scripts/run-loop.ts` + `scripts/grade.ts` (Layer 2) read.

**Read this when**:
- Authoring/modifying `run-loop.ts` or `grade.ts`
- Authoring/modifying Stage 3 archetype-aware DATA scaffolding (T-020)
- Hand-writing eval data for an existing skill being retrofitted (P9.x)
- Reviewing an `evals/` directory in a generated skill

---

## File Layout (per skill)

```
<skill>/
├── SKILL.md
├── references/
├── templates/
└── evals/
    ├── evals.json          # ALWAYS — test prompts + assertions
    ├── triggers.json       # ALWAYS — should-trigger / should-not-trigger queries
    ├── compliance.json     # SUBJECTIVE skills only — log/artifact-based stage checks
    ├── runs/               # populated by run-loop.ts
    │   └── <timestamp>/
    │       └── <test-id>.jsonl   # captured stream-json trace
    └── reports/            # populated by grade.ts
        └── <timestamp>.md
```

`evals/runs/` and `evals/reports/` are runtime-populated. Generated skills don't ship them; they're added to `.gitignore` patterns at scaffold time.

---

## evals.json — Test Prompts + Assertions

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "skills/<name>",
  "skill_version": "1.0.0",
  "grading_mode": "objective",
  "tests": [
    {
      "id": "T1",
      "description": "Trigger create-skill with a Generator-archetype spec",
      "prompt": "Create a skill that generates URL slugs from titles. Title becomes lowercase, spaces become hyphens, ASCII-only.",
      "allowed_tools": ["Read", "Write", "Edit", "Bash", "Task", "Glob", "Grep"],
      "timeout_seconds": 600,
      "assertions": [
        {
          "type": "tool_use_called",
          "tool": "Task",
          "min_count": 1
        },
        {
          "type": "file_written",
          "path_glob": "skills/slug-from-title/SKILL.md",
          "content_contains": ["name: slug-from-title", "version: 1.0.0"]
        },
        {
          "type": "stream_event_emitted",
          "event_type": "system",
          "subtype": "init",
          "field_check": {
            "plugin_errors_empty": true
          }
        },
        {
          "type": "fuzzy",
          "description": "Generated SKILL.md is internally consistent and follows Generator archetype shape",
          "evidence_paths": ["skills/slug-from-title/SKILL.md"],
          "rubric": "Header has name+version+description; Stage 1/2/3 present; cross-file claims agree with templates/"
        }
      ]
    }
  ]
}
```

### `grading_mode` field

| Value | Semantics |
|-------|-----------|
| `"objective"` | All assertions are deterministic (tool_use_called, file_written, stream_event_emitted, exit_code, regex_match). No LLM grader invoked. |
| `"subjective"` | Mix of deterministic + `fuzzy` assertions. `fuzzy` assertions invoke `skill-eval-grader.md` agent against actual artifacts, never self-report. |

Set per-archetype default in Stage 1 classification; emitted by Stage 2 scaffolding (T-020). Author may override at the Stage 1 confirmation prompt.

| Archetype | Default `grading_mode` |
|-----------|-------------------|
| Generator | `objective` |
| Tool Wrapper | `objective` |
| Script-driven | `objective` |
| Pipeline | `objective` (with optional `fuzzy` for synthesis quality) |
| Reviewer | `objective` (assertions check violation-detection precision/recall) |
| Research | `subjective` |
| Inversion | `subjective` |

Authors can override per-test.

### Assertion Types

#### `tool_use_called`
Asserts a Claude tool was invoked during the run.

```json
{
  "type": "tool_use_called",
  "tool": "Task",
  "min_count": 1,
  "max_count": 5,
  "name_matches": "create-skill-pipeline-generator"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `tool` | yes | One of: `Read`, `Write`, `Edit`, `Bash`, `Task`, `Glob`, `Grep`, `WebSearch`, `WebFetch`, etc. |
| `min_count` | no | Default 1 |
| `max_count` | no | No upper bound by default |
| `name_matches` | no | For `Task`: matches `subagent_type`. For `Bash`: regex against the command. |

Trace source: `assistant` message events with `content[].type == "tool_use"`.

#### `file_written`
Asserts a file write occurred matching path + content rules.

```json
{
  "type": "file_written",
  "path_glob": "skills/*/SKILL.md",
  "content_contains": ["name:", "description:"],
  "content_matches": "^---\\nname: [a-z-]+\\nversion:",
  "min_count": 1
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `path_glob` | yes | Glob pattern (supports `**`) |
| `content_contains` | no | Array of substrings; ALL must appear |
| `content_matches` | no | Regex (anchored as written) |
| `min_count` | no | Default 1 |

Trace source: `Write`/`Edit` tool_use events (the file_path + content fields).

#### `stream_event_emitted`
Asserts a specific stream-json event appeared.

```json
{
  "type": "stream_event_emitted",
  "event_type": "system",
  "subtype": "init",
  "field_check": {
    "plugin_errors_empty": true,
    "plugin_named": "the-bulwark"
  }
}
```

Used for verifying plugin loaded, no API retries fired beyond threshold, etc.

#### `exit_code`
Asserts the headless `claude -p` invocation exit code.

```json
{ "type": "exit_code", "value": 0 }
```

#### `regex_match`
Asserts the final `result` text matches a regex.

```json
{
  "type": "regex_match",
  "target": "result",
  "pattern": "skill .* created at skills/[a-z-]+",
  "case_insensitive": true
}
```

`target` ∈ `{"result", "all_assistant_text"}`.

#### `fuzzy` (subjective only)
Invokes `skill-eval-grader.md` with the named evidence files. Grader returns PASS/FAIL + reasoning.

```json
{
  "type": "fuzzy",
  "description": "Generated SKILL.md is internally consistent",
  "evidence_paths": ["skills/<generated>/SKILL.md", "skills/<generated>/templates/*.md"],
  "rubric": "Cross-file claims agree; archetype shape followed; CONSTRAINTS not contradicted by templates"
}
```

**HARD constraint per memo D3**: grader operates on `evidence_paths` content. NEVER on the model's self-report. The grader system prompt enforces this — `skill-eval-grader.md`.

---

## triggers.json — Should-Trigger / Should-Not-Trigger

Anthropic's 20-query format (10 + 10).

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "skills/<name>",
  "skill_version": "1.0.0",
  "should_trigger": [
    {
      "query": "Create a skill that summarizes git log",
      "reasoning": "Direct match — generation request fits create-skill"
    }
  ],
  "should_not_trigger": [
    {
      "query": "What does this code do?",
      "reasoning": "Read-only question, no generation request"
    }
  ]
}
```

Run-loop invokes `claude -p "<query>"` for each entry; grade.ts checks whether the target skill loaded (via `system/init` event's loaded-skills list, or via the first tool_use being a Task spawn into the target skill's pipeline).

Pass criterion: ≥80% of `should_trigger` triggered AND ≥80% of `should_not_trigger` did NOT trigger.

---

## compliance.json — Subjective Stage Checks (subjective skills only)

Log/artifact-based stage execution checks. The grader parses the run trace to verify the skill executed its declared stages, NOT by asking "did you do X."

```json
{
  "$schema": "eval-shape-v1",
  "skill_path": "skills/<name>",
  "skill_version": "1.0.0",
  "stages": [
    {
      "stage_id": "stage_1_classify",
      "description": "Stage 1: archetype classification interview",
      "expected_evidence": [
        {
          "type": "stream_event_emitted",
          "event_type": "assistant",
          "text_contains": "archetype"
        }
      ],
      "min_evidence_matches": 1
    },
    {
      "stage_id": "stage_2_generate",
      "description": "Stage 2: spawn Sonnet generator with CONSTRAINT",
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
      "stage_id": "stage_3_validate",
      "description": "Stage 3: anthropic-validator invocation",
      "expected_evidence": [
        {
          "type": "tool_use_called",
          "tool": "Task",
          "name_matches": "anthropic-validator"
        }
      ],
      "min_evidence_matches": 1
    }
  ]
}
```

Grader: deterministic where possible (tool_use_called, file_written). Falls back to `fuzzy` only when stage evidence cannot be expressed as a deterministic check.

---

## Runtime Trace Shape (`runs/<ts>/<test-id>.jsonl`)

Newline-delimited JSON (`stream-json` from `claude -p --output-format stream-json --verbose`). One line per event.

Key event types we parse:

| Event type | `subtype` | What we extract |
|------------|-----------|-----------------|
| `system` | `init` | `plugins[]`, `plugin_errors[]`, `model`, `tools[]`, `session_id` |
| `system` | `api_retry` | `attempt`, `error`, `error_status` (count toward retry budget) |
| `assistant` | — | `content[]` — extract `tool_use` blocks: `name`, `input`, `id` |
| `user` | — | `content[]` — extract `tool_result` blocks: `tool_use_id`, `content`, `is_error` |
| `stream_event` | — | partial deltas (only relevant if `--include-partial-messages` set) |
| `result` | — | final `result` text + `usage` |

run-loop.ts writes the entire stream verbatim. grade.ts is the parser.

---

## grading-<ts>.json (Output of grade.ts)

```json
{
  "skill_path": "skills/<name>",
  "skill_version": "1.0.0",
  "run_timestamp": "2026-04-26T08:30:00Z",
  "grading_mode": "objective",
  "summary": {
    "total_tests": 3,
    "passed": 2,
    "failed": 1,
    "pass_rate": 0.667
  },
  "tests": [
    {
      "id": "T1",
      "verdict": "PASS",
      "duration_ms": 145000,
      "exit_code": 0,
      "assertions": [
        {
          "index": 0,
          "type": "tool_use_called",
          "verdict": "PASS",
          "evidence": "Task invoked 1 time (subagent_type=create-skill-pipeline-generator)"
        }
      ]
    }
  ]
}
```

Markdown report (`reports/<ts>.md`) is the human-readable rendering of the same data.

---

## Versioning

Schema version: the `$schema` field is set to the plain identifier `eval-shape-v1`. This is **not** a resolvable URL — it's a token both `run-loop.ts` and `grade.ts` check via `.includes("eval-shape-v1")` for forward compatibility (a future stricter check is acceptable; loose matching today). The schema ships in this repo (`references/eval-shape.md`) and is read by humans, not fetched by tooling.

**When to bump to `eval-shape-v2`** — breaking changes only:
- Removing or renaming an existing top-level field in `evals.json`, `triggers.json`, `compliance.json`, or the `grading-<timestamp>.json` output
- Changing the semantics of a field already in use (e.g., redefining what `min_count` means for `tool_use_called`)
- Removing or renaming an existing assertion type
- Changing required-field status (making a previously-optional field required)

**Non-breaking — stay on `eval-shape-v1`:**
- Adding new optional fields to existing object shapes
- Adding new assertion types (e.g., a future `subagent_spawned` type)
- Adding new optional event subtypes that `stream_event_emitted` understands
- Documentation/wording clarifications

When a v2 ships, `run-loop.ts` and `grade.ts` must reject mismatched schemas with an actionable error per CS3 Fail Fast — including a one-line migration note.

---

## Pass Rate Semantics

`grade.ts` computes `summary.pass_rate = passed / total_tests` where:
- `passed` = count of tests with verdict `PASS` (every assertion was deterministic-PASS)
- `total_tests` = count of all tests in the run, including those with verdict `INCOMPLETE` (had at least one `SKIPPED` fuzzy assertion)
- `failed` = count of tests with verdict `FAIL` (at least one assertion was deterministic-FAIL)
- `incomplete` = count of tests with verdict `INCOMPLETE`

**INCOMPLETE counts in the denominator.** This means a run with deferred fuzzy grading shows a *conservative* pass rate that improves only after `skill-eval-grader` is invoked and the INCOMPLETE results are converted to PASS or FAIL. This is intentional — it surfaces the deferred work in the headline number rather than hiding it.

If you want the deterministic-only pass rate, compute `passed / (passed + failed)` from the summary block; the JSON is structured for that.

---

## Cross-References

- `references/eval-scaffolding.md` — Per-archetype emission guide for Stage 2 (T-020); placeholder substitution markers; sub-pattern × eval impact table
- `scripts/run-loop.ts` — reads evals.json + triggers.json + compliance.json; writes runs/
- `scripts/grade.ts` — reads runs/ + evals.json; writes grading.json + reports/
- `agents/skill-eval-grader.md` — invoked by grade.ts for `fuzzy` assertions; artifact-based; HARD constraint against self-report grading
- `agents/skill-eval-comparator.md` — A/B compares two grading.json files
- Memo D3 (`docs/internal/p10.2-part-b-scope-decision.md`) — log/artifact grading hard constraint
