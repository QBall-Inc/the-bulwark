# Step 2 — Verification Methods

## Purpose

For each claim in the Stage 1 checklist, run a concrete verification command (Grep, Read, Bash, or `git log`) against current code or current state. Capture the actual current state alongside the claim. Do NOT mark a claim CONFIRMED until you have verifiable evidence — and the evidence is a verbatim quote, not a paraphrase or recollection.

This stage is **per-claim**, not per-file. A single file may host many claims; each one gets its own verification.

---

## Per-Claim-Type Recipes

### File path claims

**Verification method**: Read or `ls`. Confirm the file exists and is at the path the spec asserts.

**Recipe**:
```bash
# Tool: Bash
ls -la <path>
# OR
test -f <path> && echo "EXISTS" || echo "MISSING"
```

Or via the Read tool — if Read returns content, the path exists.

**Expected output (CONFIRMED)**: file exists at the asserted path.

**Drift signal**: file does not exist (→ DRIFT-wrong-file or GAP, depending on whether a similar path exists), OR the file exists but at a different path (→ DRIFT-wrong-file, severity HIGH).

---

### Line ref claims

**Verification method**: Read at the specific line offset. Confirm the content matches the spec's assertion verbatim.

**Recipe**:
```text
Tool: Read
file_path: <path>
offset: <line - 5>    # read a few lines before for context
limit: 15             # plus context after
```

Then compare the returned content at the asserted line against the spec's claim **verbatim**.

**Expected output (CONFIRMED)**: the content at `<file>:<line>` matches the spec's quoted/described content.

**Drift signal**:
- Same file, different line (the content has moved) → DRIFT-line-ref, severity LOW
- Different file entirely (file was renamed) → DRIFT-wrong-file, severity HIGH
- Content gone entirely → GAP, severity HIGH

---

### Function / method / class / type name claims

**Verification method**: Grep for the symbol. Confirm definition + at least one usage. Read the definition site to confirm signature/shape matches the spec.

**Recipe**:
```bash
# Tool: Grep
# Find the definition
pattern: "^(function|def|class|export\\s+function|public\\s+\\w+)\\s+<name>"
# Find usages
pattern: "<name>\\b"
output_mode: "files_with_matches"
```

Then Read the definition site to confirm the signature.

**Expected output (CONFIRMED)**: symbol is defined exactly once (or appropriately for an overload) at the asserted location, with the signature/shape the spec describes.

**Drift signal**:
- Symbol does not exist anywhere → GAP, severity HIGH
- Symbol exists but in a different file → DRIFT-wrong-file, severity HIGH
- Symbol exists but signature differs → AC re-interpretation OR drift, severity MEDIUM (resolve explicitly in Stage 3)

---

### Constant / schema version / enum value claims

**Verification method**: Grep for the declaration. Read the declaration line to confirm value.

**Recipe**:
```bash
# Tool: Grep
pattern: "<CONSTANT_NAME>\\s*[=:]"
output_mode: "content"
-n: true
-B: 0
-A: 1
```

Then Read at the line to confirm the literal value.

**Expected output (CONFIRMED)**: declaration exists, literal value matches.

**Drift signal**:
- Declaration missing → GAP, severity HIGH
- Declaration present, value differs → DRIFT-line-ref or AC re-interpretation, severity MEDIUM (the value matters)
- Multiple declarations (collision) → DRIFT-undeclared-scope, severity MEDIUM

---

### Sequence-of-events claims

**Verification method**: Read the calling code. Confirm the order matches the spec's assertion. For pipeline / hook claims, read the orchestrator (the file that wires the sequence).

**Recipe**:
```text
Tool: Read
file_path: <orchestrator path>
# Read the full sequence; do NOT skim
```

Then trace: where is op A invoked? where is op B invoked? Is A's invocation site lexically (or temporally, for async) before B's?

**Expected output (CONFIRMED)**: A precedes B as the spec asserts.

**Drift signal**:
- A and B are in opposite order → DRIFT-line-ref or AC re-interpretation, severity MEDIUM (logic may have changed)
- A or B does not exist in the orchestrator → GAP, severity HIGH

---

### Dependency claims (shipped-in / in_progress / pending)

**Verification method**: `git log --grep=` for the WP / feature name, AND read the source-of-truth state artifact (`plans/active_tasks.yaml`, `plans/tasks_completed.yaml`, or session handoff).

**Recipe**:
```bash
# Tool: Bash
git log --oneline --grep="<WP-id-or-feature>" | head -20
# Cross-check against state artifact
grep -n "<WP-id>" plans/active_tasks.yaml plans/tasks_completed.yaml
```

**Expected output (CONFIRMED)**: a commit referencing the WP exists in git history AND the state artifact reflects the asserted status.

**Drift signal**:
- No commit found AND state artifact lists status=pending → DRIFT-line-ref or GAP, severity depends on whether downstream depends on it
- Commit exists but state artifact lists wrong status → DRIFT-line-ref, severity LOW (state-tracking drift, not blocking)
- WP claim is for a future session ("will ship in S130") → not verifiable; flag as state claim and defer

---

### State claims (current_task, POST-N status, in_progress markers)

**Verification method**: Read the source-of-truth artifact directly. Quote the relevant field verbatim.

**Recipe**:
```text
Tool: Read
file_path: plans/active_tasks.yaml
# OR
file_path: plans/tasks_completed.yaml
# OR
file_path: <session handoff>
```

Then locate the field and verbatim-quote it back into the verification log.

**Expected output (CONFIRMED)**: field value matches the spec's claim verbatim.

**Drift signal**:
- Field present, value differs → DRIFT-line-ref, severity LOW (state has moved on)
- Field missing entirely → GAP, severity HIGH

---

## Handoff / Memory Recall vs Grep-Quote (BINDING)

When a claim references a handoff document, a memory entry, or a prior conversation:

- **MUST grep + verbatim quote.** Open the document, locate the asserted text, copy it verbatim into the verification log's `actual_state` field.
- **MUST NOT recall.** Recalling what a session handoff said three sessions ago is recall-style verification. It hallucinates, frequently. Recall fails silently — the verifier writes a confident "CONFIRMED" that is, on second look, wrong.
- **If the verbatim quote does not match the spec's claim**, this is drift. Severity depends on what the claim is load-bearing for.

This rule is non-negotiable. See `anti-patterns.md` for the full anti-pattern catalog.

---

## What Counts as Verbatim Evidence

| Evidence form | Verbatim? | Use as proof? |
|---------------|-----------|---------------|
| Tool output captured in the verification log | Yes | Yes |
| Quoted file content from a Read call | Yes | Yes |
| Grep output line | Yes | Yes |
| Paraphrased summary of what a file says | No | No — re-Read and quote verbatim |
| "I remember the handoff said..." | No | No — open and quote |
| "The pattern looks like..." | No | No — Grep and quote a specific match |

## Output of Stage 2

Stage 2 produces, for each claim C-N from Stage 1, one of:

- **CONFIRMED**: claim matches verifiable current state. Capture the verbatim evidence in the verification log.
- **DRIFT-<variant>**: claim does not match. Capture both the spec's verbatim assertion AND the actual current state (verbatim).
- **VERIFICATION_ERROR**: command failed (file unreadable, grep timed out, etc.). Capture the error; do NOT default to CONFIRMED.

The Stage 2 output flows directly into Stage 3 (categorization). Each finding gets a `D-N` identifier; the `C-N` from Stage 1 is preserved as the `claim_id` for traceability.
