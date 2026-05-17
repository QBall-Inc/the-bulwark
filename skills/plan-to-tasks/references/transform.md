# Plan-to-Tasks Transformation Algorithm

Full transformation algorithm + CLEAR schema reference. Loaded by `plan-to-tasks/SKILL.md` Stages 4–7.

---

## CLEAR Schema Reference

The schemas below are the runtime source of truth — match field names exactly. If you have access to the CLEAR framework codebase locally during Bulwark contributor work, the canonical examples live at:

- `clear-framework/plans/clear-v1-completion/tasks.yaml` — parent-style example
- `clear-framework/plans/knowledge-system-overhaul/tasks.yaml` — child-style example
- `clear-framework/plans/knowledge-system-overhaul/workpackages/WP-K0.1.yaml` — per-WP example

These external references are validation aids for contributors. If a CLEAR canonical file disagrees with the schema below (because CLEAR evolves), **update this reference** — do not silently diverge at the skill output. The schemas in this file are what `plan-to-tasks` produces.

---

## `tasks.yaml` Schema (CLEAR-compatible + Bulwark `parent_plan` divergence)

```yaml
project: <plan-slug>
version: <semver string from plan frontmatter, or 1.0.0>
created: "<YYYY-MM-DD>"
updated: "<YYYY-MM-DD>"
current_phase: <id of current phase, or first phase>
current_task: <id of WP in progress, or null>
current_task_status: "<short status string, may be empty>"
plan_file: "plan_v{N}.md"

# BULWARK DIVERGENCE: parent_plan field (only present in child plans)
parent_plan: <relative path to parent plan dir from repo root>

phases:
  - id: <phase-id>
    name: "<phase name>"
    description: "<one-line description>"
    status: not_started | in_progress | complete
    tasks:
      - id: WP-<id>
        name: "<short name>"
        status: not_started | in_progress | complete | blocked
        dependencies: [<list of WP ids this blocks-on>]
        detail_file: "workpackages/WP-<id>.yaml"
        estimated_sessions: <number or "N-M" range string>
        note: "<optional short note>"

milestones:
  - id: <milestone-id>
    name: "<milestone name>"
    phase: <phase-id>
    type: major | minor | gate
    requires: [<list of WP ids>]
    status: not_started | in_progress | complete

summary:
  total_tasks: <integer>
  completed_tasks: <integer>
  active_work: "<one-line summary>"
  next_priorities:
    - "<priority 1>"
    - "<priority 2>"
```

**Notes**:
- `parent_plan` is the ONLY allowed divergence from CLEAR. Document its presence in any plan it appears in.
- `phases[]` may collapse to a single phase when the source `plan_v{N}.md` does not explicitly partition by phase. In that case, default `phase.id = "main"` and `phase.name = "Main"`.
- `milestones[]` is OPTIONAL. Include only if the source plan defines milestones; otherwise omit the section entirely.

---

## `WP-<id>.yaml` Schema (CLEAR-compatible)

```yaml
id: WP-<id>
title: "<short title — same as tasks.yaml entry's name>"
phase: <phase-id from parent tasks.yaml>
status: not_started | in_progress | complete | blocked
dependencies: [<WP ids>]
estimated_sessions: <number or "N-M" range>

acceptance_criteria:
  - "<testable criterion 1>"
  - "<testable criterion 2>"

deliverables:
  - "<concrete output 1>"
  - "<concrete output 2>"

verification:
  - "<verification step 1>"
  - "<verification step 2>"

notes:
  - "<supporting context 1, with attribution if from a specific role e.g. (TA: ..., QA: ...)>"
  - "<supporting context 2>"
```

**Notes**:
- Field name is `title`, NOT `name` or `description`. Match CLEAR exactly.
- Each section (`acceptance_criteria`, `deliverables`, `verification`, `notes`) is an array of strings.
- The brief originally suggested `name` + `description` + `blocks` fields. CLEAR's actual files use `title` and do not include `blocks`. We follow CLEAR.

---

## Stage Algorithms

### Stage 1 — Input Resolution

```
arg = $1
if arg is empty:
    Use AskUserQuestion to ask for the plan path
if arg is not a file:
    fail fast: "Plan file not found: {arg}"
plan_path = absolute path of arg
plan_dir = dirname(plan_path)
```

### Stage 2 — Parent/Child via AskUserQuestion

See `references/askuserquestion-prompts.md` for the exact question schemas. After Stage 2 completes, you have:

```
parent_child_mode: "standalone" | "child"
parent_plan_path: <repo-relative path to parent plan dir, or null>
plan_slug: <directory slug for this plan — defaults to dirname(plan_path)'s basename>
target_plan_dir: <plans/{slug} relative to repo root>
```

### Stage 3 — Read Plan + Synthesis Artifacts

Glob `{plan_dir}/*` for any of:
- `plan_v{N}.md` (the source plan — required)
- `r{round}-*.md` (round-by-round artifacts if any)
- `synthesis*.md` (synthesis docs)
- `research-*.md`, `brainstorm-*.md` (upstream research/brainstorm artifacts)
- Any other `.md` siblings of the plan file

Read each into context. These are the source materials for sub-agent expansion at Stage 5.

### Stage 4 — Extract WP List

Parse the YAML blocks in `plan_v{N}.md`. Plan-creation emits per-WP YAML blocks of the form:

```yaml
id: WP-X
name: "..."
description: "..."
dependencies: [...]
```

Extract every block. Build an in-memory list:

```
workpackages = [
  {id, name, description, dependencies, optional_phase_id}, ...
]
```

If the plan groups WPs by phase, capture the phase mapping. Otherwise default all WPs to a single `phase.id = "main"`.

### Stage 5 — Per-WP Expansion (Parallel Sonnet Sub-Agents)

Spawn parallel sub-agents in batches of **≤5**. Use the 4-part subagent-prompting template:

```
GOAL: Expand WP-<id> ("{name}") from the plan into a CLEAR-compatible workpackages/WP-<id>.yaml file.

CONSTRAINTS:
- Match the CLEAR per-WP schema exactly (field names: id, title, phase, status, dependencies, estimated_sessions, acceptance_criteria, deliverables, verification, notes).
- Acceptance criteria must be testable (each entry is a discrete pass/fail check).
- Deliverables must be concrete outputs (file paths, code components, tests, docs — not abstract goals).
- Verification steps must be executable or observable.
- Use plan + synthesis docs as the source of truth — do NOT invent acceptance criteria not implied by the source.
- If the source is sparse, write a sparse YAML — flag missing context in the `notes` field rather than fabricating.

CONTEXT:
- Plan content: {full text of plan_v{N}.md}
- Synthesis docs: {full text of all relevant *.md siblings}
- WP being expanded: {id, name, description, dependencies}
- Phase id: {phase_id from Stage 4 mapping}
- Target output path: {target_plan_dir}/workpackages/WP-<id>.yaml

OUTPUT:
Write the YAML directly to {target_plan_dir}/workpackages/WP-<id>.yaml.
Return a 3-line summary to main context: WP-<id>, deliverables count, any TODO flags.
```

**Batching**: with 7 WPs, batch as 5 + 2. With 12 WPs, batch as 5 + 5 + 2. Never spawn more than 5 sub-agents in a single message.

### Stage 6 — Generate `tasks.yaml`

Compose the lightweight index using the schema above. Fill `phases`, `tasks` (per-WP entries), and `summary`. Include `parent_plan` field if `parent_child_mode == "child"`.

Write to `{target_plan_dir}/tasks.yaml`.

### Stage 7 — Update Parent `tasks.yaml` In-Place (If Child)

Only if `parent_child_mode == "child"`:

1. Read the parent's `tasks.yaml`.
2. Determine where to insert the child reference. Default placement: under the parent's last phase's `tasks:` array, append a single entry:

```yaml
- id: WP-CHILD-{slug}
  name: "Child plan: {plan_slug}"
  status: not_started
  dependencies: []
  detail_file: "{relative path from parent plan dir to child tasks.yaml}"
  estimated_sessions: <sum of child WP sessions>
  note: "Child plan auto-linked by plan-to-tasks. See {child_path}/plan_v{N}.md for full plan."
```

3. Write the parent's `tasks.yaml` back in place.

**Safety**: if parent's `tasks.yaml` already contains an entry referencing this child slug, replace it (idempotent) rather than appending a duplicate.

### Stage 8 — Emit Summary

Print to stdout:

```
plan-to-tasks: complete
- {N} workpackages written to {target_plan_dir}/workpackages/
- tasks.yaml written to {target_plan_dir}/tasks.yaml
- parent linkage: {standalone | linked to {parent_path}}
- next: open the first not_started workpackage and begin work, or run downstream tooling that consumes tasks.yaml
```

---

## Failure Modes

| Mode | Action |
|------|--------|
| Plan path not found | Fail fast with actionable error |
| Plan has no YAML WP blocks | Print the warning, ask if user wants to proceed with a single-WP fallback |
| `workpackages/` already exists | AskUserQuestion before overwriting (AC8) |
| Sub-agent fails to produce valid YAML | Re-spawn that single sub-agent once; if still fails, write a stub WP with a `notes:` flag and continue |
| Bogus parent path | Fail fast BEFORE modifying any files |
| Parent `tasks.yaml` malformed | Print the warning, do NOT modify the parent, finish child writes anyway |

---

## Idempotency Note

`plan-to-tasks` re-run on the same plan should:
- Re-prompt before overwriting existing `workpackages/` (AC8 safety gate).
- Re-generate `tasks.yaml` cleanly.
- For the parent's `tasks.yaml` (child mode), de-duplicate child references on re-run.

This is best-effort; the v1 contract trusts user judgment when re-running.
