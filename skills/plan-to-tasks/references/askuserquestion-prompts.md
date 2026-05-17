# AskUserQuestion Prompts — plan-to-tasks Stage 2

Exact AskUserQuestion schemas for parent/child detection + slug confirmation. Loaded by `plan-to-tasks/SKILL.md` Stage 2.

---

## Question 1 — Parent/Child Mode

**Trigger**: Always asked at Stage 2.

```yaml
question: "Is this plan a child of an existing parent plan?"
multiSelect: false
options:
  - label: "Standalone (or parent plan)"
    value: "standalone"
    description: "This plan stands alone — no parent linkage. Generate tasks.yaml without a parent_plan field."
  - label: "Child plan"
    value: "child"
    description: "This plan is a child of an existing parent plan. Capture parent path + add parent_plan field to generated tasks.yaml + append a child reference entry to the parent's tasks.yaml."
```

**Decision flow**:
- `standalone` → skip Question 2; proceed with Question 3.
- `child` → ask Question 2.

---

## Question 2 — Parent Plan Path (Conditional on `child`)

**Trigger**: Only if Question 1 answered `child`.

```yaml
question: "Repo-relative path to parent plan directory (containing the parent plan_v{N}.md and tasks.yaml)?"
multiSelect: false
options: []  # Free-text response
```

**Validation**:
- Path must resolve to an existing directory.
- Directory must contain a `tasks.yaml` (parent must already have been processed by `plan-to-tasks` or be CLEAR-shaped from another source).
- If validation fails, re-ask with the specific failure reason ("Directory not found at {path}" or "tasks.yaml missing in {path}").

---

## Question 3 — Plan Slug Confirmation

**Trigger**: Always asked at Stage 2.

```yaml
question: "Slug for this plan directory (lowercase-kebab; default derived from plan filename)?"
multiSelect: false
options: []  # Free-text response, with default suggestion shown
```

**Default**: Strip `plan_v{N}.md` from filename and use the parent directory's basename. Example: `plans/auth-rewrite/plan_v1.md` → default slug `auth-rewrite`.

**Validation**:
- Must match `^[a-z0-9][a-z0-9-]*[a-z0-9]$` (lowercase-kebab, no spaces, no underscores, alphanumeric + hyphens, no leading/trailing hyphen).
- If invalid, re-ask with the specific failure reason.

---

## After Stage 2

After Q1–Q3 answered, the orchestrator has:

```yaml
parent_child_mode: "standalone" | "child"
parent_plan_path: "<absolute path to parent plan dir>" | null
plan_slug: "<validated lowercase-kebab slug>"
target_plan_dir: "plans/<plan_slug>"  # repo-relative
```

These values flow into Stages 3–7.
