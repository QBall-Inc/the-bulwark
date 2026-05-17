# Step 1 — Claim Extraction

## Definition

A **verifiable claim** is any concrete factual statement in the spec that can be checked against current code, current state, or current dependencies. Claim extraction is the act of reading the spec end-to-end and enumerating every such statement into a numbered checklist, ordered by load-bearing-ness (the claims that drive the most downstream work first).

Claim extraction is the foundational step. Every later stage operates on the checklist produced here. **Skipping or under-extracting at this stage is the highest-leverage anti-pattern** — embedded claims that go unverified become silent drift later. See `anti-patterns.md` for context.

## Procedure

1. **Read the entire spec end-to-end first.** Do NOT extract claims as you scroll on first read; you will miss cross-references and mis-prioritize.
2. **On the second pass, enumerate.** For each section that makes a factual assertion, copy the verbatim claim into the checklist. Do NOT paraphrase — recall hallucinates; verbatim is the only safe form.
3. **Order by load-bearing-ness.** A claim that drives a deliverable, a path target, or a sequence-of-events ordering is load-bearing. A claim that is decorative ("this matches the existing style") is not. Load-bearing claims first.
4. **Stop when every concrete factual claim is captured.** Hand-wavy claims ("works well", "fits the pattern") are NOT claims and should not be in the checklist.

## Claim Types (Taxonomy)

### 1. File path claims

A specific repo-relative path is asserted to exist or to be the target of an action.

**How to spot**: Backtick-quoted paths (`src/foo/bar.ts`), code blocks listing a path, paths in tables under a "File" column.

**Example**:
> "The fix lives in `scripts/hooks/suggest-pipeline-stop.sh`."

**Output format** (in checklist):
> C-01: file path `scripts/hooks/suggest-pipeline-stop.sh` exists.

### 2. Line ref claims

A specific line number (or range) within a file is asserted to contain specific content.

**How to spot**: `file.ts:174`, `bar.sh:12-18`, "the function at line 42", "around line 200".

**Example**:
> "The recursion bug is at `coverage_check.py:88`."

**Output format**:
> C-02: line `coverage_check.py:88` contains the recursion bug (specifically: the `parse_followup_edits_expected` early-return path).

### 3. Function / method / class / type name claims

A named symbol is asserted to exist at a specific location, with specific behavior, or as a specific shape.

**How to spot**: Backtick-quoted identifiers (`parseFollowupEdits()`, `class TestAuditOrchestrator`), prose like "the `foo` function", `def bar:` patterns.

**Example**:
> "Add `grace_window_seconds` to the `followup_edits_expected` schema."

**Output format**:
> C-03: schema field `followup_edits_expected.grace_window_seconds` exists / will be added.

### 4. Constant / schema version / enum value claims

A specific literal value is asserted (a port number, a version string, an enum member, a default).

**How to spot**: Numeric literals in prose, `version: 1.2.0`, `default 1800`, `MAX_FILE_SIZE = 10MB`.

**Example**:
> "The default grace window is 1800 seconds."

**Output format**:
> C-04: default `grace_window_seconds` value is `1800` in code.

### 5. Sequence-of-events claims

Two or more operations are asserted to happen in a specific order, or one is asserted to call / depend on the other.

**How to spot**: "X is called before Y", "after Stage 2, ...", "the hook fires when ...", arrow / pipe diagrams (`A |> B |> C`), sequence-numbered lists.

**Example**:
> "The Stop hook coverage check reads the diagnostic log BEFORE evaluating the post-fix edits."

**Output format**:
> C-05: in `suggest-pipeline-stop.sh`, diagnostic log read precedes the post-fix edit evaluation.

### 6. Dependency claims

A WP, a feature, a fix, or a piece of work is asserted to have shipped (or to be in_progress / pending) in a specific session, branch, or commit.

**How to spot**: "depends on WP-Foo which shipped in S150", "P10.20 is pending", "this builds on the fix from commit abc123".

**Example**:
> "P10.22 (Stop hook post-fix grace period) shipped in S121 and provides the `followup_edits_expected` field this skill consumes."

**Output format**:
> C-06: P10.22 shipped (status=completed in `active_tasks.yaml`); `followup_edits_expected` field is consumed by `coverage_check.py`.

### 7. State claims

A source-of-truth artifact is asserted to be in a specific state right now (POST-N is resolved, current_task points to X, status is Y, the skill ships at v1.2.0).

**How to spot**: "currently shows", "active_tasks.yaml has...", "the in_progress task is...", "POST-29 is resolved".

**Example**:
> "`active_tasks.yaml` current_task is P10.18."

**Output format**:
> C-07: `plans/active_tasks.yaml` `current_task` field equals `P10.18`.

## Checklist Template

Use this scaffold to fill the Stage 1 output. Numbering is sequential (C-01, C-02, ...) and persists into Stage 2 (each verification logs against the same C-N) and Stage 3 (each finding inherits the C-N as part of its D-N id).

```markdown
## Claim Checklist — {spec-path}

Spec: {spec-path}
Spec read date: {YYYY-MM-DD}
Total claims: {N}

### File path claims
- [ ] C-01: file path `<path>` exists.
- [ ] C-02: file path `<path>` exists.

### Line ref claims
- [ ] C-03: line `<file>:<line>` contains `<claim about content>`.

### Function / class / type claims
- [ ] C-04: function `<name>` exists at `<path>` with signature `<...>`.
- [ ] C-05: type `<name>` is exported from `<path>`.

### Constant / schema / enum claims
- [ ] C-06: constant `<name>` has value `<literal>` in `<path>`.

### Sequence-of-events claims
- [ ] C-07: in `<path>`, `<op A>` precedes `<op B>`.

### Dependency claims
- [ ] C-08: `<WP / feature>` is `<status>` per `<source-of-truth artifact>`.

### State claims
- [ ] C-09: `<artifact>` field `<field>` equals `<value>` right now.
```

## When to Stop Extracting

- Every concrete factual claim is captured.
- The remaining text in the spec is rationale, narrative, prose, or non-claim guidance.
- Hand-wavy assertions ("this is consistent with current style") are NOT claims; do not add them.

If you are in doubt about whether something is a claim, ask: "Could this be wrong, and if it were wrong, would the next action go off the rails?" If yes, it's a claim. If no, skip it.

## Output

The Stage 1 output is the numbered checklist above, with the `[ ]` boxes left unchecked. Stage 2 fills them in (or flags drift). The checklist becomes part of the verification log written in Stage 5 (under `verification_checklist:`).
