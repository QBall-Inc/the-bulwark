# plan-to-tasks

Transform a `plan-creation` plan into CLEAR-compatible execution structure: a `tasks.yaml` workpackage index plus per-WP YAML files under `workpackages/`. Optional parent/child plan linkage with bidirectional reference.

## When to use

- Right after `plan-creation` finishes and you want execution-friendly task structure.
- When existing tooling (cf-cli, lifecycle-cli, custom orchestrators) expects CLEAR-shaped task YAML.
- For multi-plan trees: child plans add a `parent_plan` backlink + append a reference to the parent's `tasks.yaml`.

## Usage

```
/plan-to-tasks <path-to-plan_v{N}.md>
```

Example:

```
/plan-to-tasks plans/auth-rewrite/plan_v1.md
```

## What it produces

```
plans/<slug>/
├── plan_v{N}.md          # untouched — source plan
├── tasks.yaml            # NEW — WP index
└── workpackages/         # NEW
    ├── WP-001.yaml
    ├── WP-002.yaml
    └── ...
```

If you answer "Yes (child plan)" to the parent/child question, the parent's `tasks.yaml` also gets a single reference entry pointing back to this child.

## Schema match with CLEAR

Both `tasks.yaml` and `WP-{id}.yaml` match CLEAR's canonical schema exactly, with one intentional Bulwark divergence:

- **`parent_plan`** (in `tasks.yaml` of child plans only) — relative path to the parent plan directory, enabling bidirectional traversal of parent ↔ child plan trees. CLEAR's parent-references-child convention is one-directional; Bulwark adds the reverse pointer for discoverability.

The reference files at `references/transform.md` and `references/askuserquestion-prompts.md` document the full schemas + AskUserQuestion flow.

## How it works

The skill orchestrates parallel Sonnet sub-agents to expand each workpackage into its full per-WP YAML using:
1. The source `plan_v{N}.md` (extracted YAML WP blocks)
2. Sibling synthesis artifacts in the plan directory (round outputs, synthesis docs, research/brainstorm if present)

Sub-agents work in batches of ≤5. The orchestrator never writes per-WP YAML directly — it dispatches and aggregates.

## Acceptance criteria + verification

See the P10.5 brief at `plans/task-briefs/P10.5-plan-to-tasks-skill.md` for the full acceptance criteria (AC1–AC10) and verification plan (V1–V7).

## Related skills

- [plan-creation](plan-creation.md) — produces the source `plan_v{N}.md` consumed by this skill. Stage 5 of `plan-creation` emits a soft hint pointing at `/plan-to-tasks` after the plan is written.
