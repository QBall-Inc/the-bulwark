# UPDATE MODE — Step-by-Step Procedure

This is the BINDING reference for Stage 9 (UPDATE MODE) in `SKILL.md`. Load before executing `--update`.

UPDATE MODE handles the propagation gap: `/plugin` updates plugin-owned assets (skills/agents/hooks/scripts/templates) but cannot touch user-owned files that init writes (CLAUDE.md, rules.md, optionally Justfile + statusline config). Without UPDATE MODE, canonical template additions never reach existing users — the precise pattern that motivated SD1 + this skill.

**Design contract**: UPDATE MODE is interactive per-section. Every change to a user-owned file requires explicit user Accept. No auto-apply, no bulk mode, no fallback that silently writes. The user is the explicit decision point on every section.

---

## 9a — Read Marker

```bash
# Resolve scope from $ARGUMENTS or interactive prompt
if [ "$SCOPE" = "user" ]; then
  SCOPE_ROOT="$HOME"
else
  SCOPE_ROOT="${TARGET:-.}"
fi
MARKER="${SCOPE_ROOT}/.bulwark/init-marker.yaml"
```

The marker schema (written by `scripts/init.sh` per Stage 7):

```yaml
version: "1.2.0"             # Bulwark version at install / last update
init_at: "2026-05-09T22:30:00Z"
scope: project | user
scope_root: "/abs/path/to/scope/root"
artifacts_written:
  - path: "CLAUDE.md"        # relative to scope_root
    canonical: "lib/templates/claude.md"  # relative to plugin root
  - path: ".claude/rules/rules.md"
    canonical: "lib/templates/rules.md"
```

`artifacts_written` drives the diff: for each entry, UPDATE MODE compares `${SCOPE_ROOT}/${path}` (user's file) against `${CLAUDE_PLUGIN_ROOT}/${canonical}` (the latest plugin canonical).

### Backward Compatibility

If `MARKER` is absent, this project either was never Bulwark-initialized OR was initialized pre-v1.2.0 (before the marker existed). Surface to the user via AskUserQuestion before proceeding:

```
question: "No init marker found at ${MARKER}. Was this project Bulwark-initialized? (--update needs a marker to know which files to compare)"
header: "Backward-compat check"
multiSelect: false
options:
  - label: "Yes, write marker for current state and proceed"
    description: |
      I'll generate a marker assuming the standard init layout
      (CLAUDE.md at scope root + rules.md at .claude/rules/rules.md).
      You can then re-run --update to review template drift normally.
  - label: "No, this is a custom Rules.md project"
    description: |
      Skip --update; your Rules.md is hand-rolled and not derived from
      Bulwark templates. The SessionStart drift hook also silent-skips
      when the marker is absent.
  - label: "Run /the-bulwark:init first to install marker"
    description: |
      If you intended to initialize Bulwark fully, run the fresh init
      flow (which writes the marker) instead of --update.
```

If the user chooses "Yes, write marker", emit the marker with the standard schema (matching what fresh init.sh would write), then continue from 9b. If "No", exit cleanly. If "Run init first", exit with a pointer to `/the-bulwark:init`.

---

## 9b — Compute Drift

Invoke the helper script:

```bash
DRIFT_REPORT="${SCOPE_ROOT}/.bulwark/drift-report-$(date -u +%Y%m%d-%H%M%S).yaml"
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update.sh" --check \
  --marker="$MARKER" \
  --plugin-root="$CLAUDE_PLUGIN_ROOT" \
  --output="$DRIFT_REPORT"
```

The report schema:

```yaml
generated_at: "2026-05-09T22:30:00Z"
marker_version: "1.2.0"
plugin_version: "1.3.0"
total_drift_items: 3
artifacts:
  - path: "CLAUDE.md"
    canonical: "lib/templates/claude.md"
    drift_items:
      - anchor: "### Pre-WP Spec Drift Check (SD1 binding)"
        canonical_excerpt: |
          (first 5 lines of canonical content for the anchor)
  - path: ".claude/rules/rules.md"
    canonical: "lib/templates/rules.md"
    drift_items:
      - anchor: "## Spec Drift Rules (SD)"
        canonical_excerpt: |
          (first 5 lines)
      - anchor: "### SD1: Pre-WP Spec Drift Check"
        canonical_excerpt: |
          (first 5 lines)
```

If `total_drift_items == 0`, present "No template changes to review. Your Bulwark config is up to date." and exit cleanly.

---

## 9c — Pre-Flight Confirmation

Single AskUserQuestion summarizing the drift report before entering the batched per-section loop:

```
question: "Detected ${total_drift_items} section additions across ${artifact_count} files. Sections will be presented in batches of up to 4 per AskUserQuestion (tabbed view). Proceed?"
header: "Update preview"
multiSelect: false
options:
  - label: "Proceed with batched review"
    description: |
      Sections are presented in batches of ≤4 per AskUserQuestion call.
      Each tab shows one section with Accept/Skip options; submit the
      whole batch in one go. After all batches are processed, Accepted
      sections are applied sequentially (any apply failure aborts the run).
  - label: "Show full content for all sections first"
    description: |
      Print every section's FULL canonical content to stdout (not just
      the 5-line excerpt in the drift report). Use this to inspect what
      you'll be reviewing BEFORE entering the batched decision loop.
      Reads ${DRIFT_REPORT} and dumps full per-anchor content from each
      canonical template; then re-fires this same pre-flight prompt.
  - label: "Cancel — exit without changes"
    description: |
      No files will be modified. The marker is unchanged. The
      SessionStart drift hook will continue to flag drift next session.
```

On **Show full content for all sections first**, for each `artifacts[*].drift_items[*]` in the drift report, extract the full section body from `${CLAUDE_PLUGIN_ROOT}/${artifact.canonical}` (anchor through next same-or-shallower header). Print to stdout in a structured form (one section per anchor, fenced by anchor line). After all sections printed, re-fire this pre-flight AskUserQuestion so the user can then decide Proceed or Cancel with full information in hand.

This option REPLACES the previous per-section "Show full" re-prompt: full-content inspection now happens upfront in 9c, not mid-loop. Rationale: batched 9d loop has 4 simultaneous decisions per call; an inline Show-full would require breaking the batch, increasing UX complexity. Pre-flight inspection is sufficient.

---

## 9d — Batched Interactive Review Loop

Drift items are flattened into a single ordered list across all artifacts (preserves canonical order within each artifact, processes artifacts in `drift_report.artifacts[*]` order). Items are then grouped into batches of up to 4 per AskUserQuestion call (the tool's maximum questions-per-call). Each batch fires ONE AskUserQuestion with N questions (N = min(remaining, 4)), rendered as tabbed view in the UI; the user navigates tabs freely and submits all N decisions in one batch.

### Algorithm (BINDING)

```
flat_items = []
for artifact in drift_report.artifacts:
  for drift_item in artifact.drift_items:
    flat_items.append({artifact, drift_item, absolute_index, total})

batches = chunk(flat_items, size=4)   # [items_1..4], [items_5..8], ...

for batch in batches:
  questions = []
  for item in batch:
    questions.append({
      question: "${item.artifact.path} — Apply '${item.drift_item.anchor}'?",
      header: "Section ${item.absolute_index}/${item.total}",
      multiSelect: false,
      options: [
        { label: "Accept — apply this section",
          description: <see Stage 9d template in update-askuser-prompts.md> },
        { label: "Skip — don't apply this section",
          description: <see Stage 9d template> }
      ]
    })

  decisions = AskUserQuestion(questions)   # SINGLE tool call with N questions

  # Sequential apply within the batch — preserves Stage 9 abort-on-failure contract
  for (item, decision) in zip(batch, decisions):
    if decision == "Accept":
      run: bash "${CLAUDE_PLUGIN_ROOT}/scripts/apply-section.sh" \
             --target="${SCOPE_ROOT}/${item.artifact.path}" \
             --canonical="${CLAUDE_PLUGIN_ROOT}/${item.artifact.canonical}" \
             --anchor="${item.drift_item.anchor}"
      if exit != 0: STOP (write audit log + fire 9d-error AskUserQuestion + abort)
      else: record applied in audit log
    else:  # Skip
      record skipped in audit log
```

For each Accept in a batch, `apply-section.sh` is invoked SEQUENTIALLY (not in parallel) so file writes are linearized and a mid-batch failure aborts before subsequent applies attempt. The helper handles position-aware insertion — see [update-section-anchor-diff.md § Insertion Algorithm](update-section-anchor-diff.md#insertion-algorithm) for placement rules.

### Show-full behavior (REMOVED from 9d, moved to 9c)

There is NO inline "Show full" option in 9d. Full per-section content inspection happens upfront in 9c (Pre-Flight Confirmation) — that's the single canonical place to view full content before deciding. Rationale per S124 P10.24 brief: batched 9d has 4 simultaneous decisions per call; breaking the batch for a single "Show full → re-prompt" cycle would force the user to re-enter prior decisions, complicating the UX without value once content is viewable upfront.

### State invariants per iteration

- Every `apply-section.sh` invocation MUST exit 0 before continuing within the batch. Non-zero → STOP entire run, write audit log with partial-state warning (record which items in earlier batches were applied, which were skipped, which item failed), surface error to user via Stage 9d-failure AskUserQuestion (see update-askuser-prompts.md).
- Each section's decision (applied | skipped) is recorded in the audit log entry for traceability. Batch boundaries are NOT recorded as separate audit events — only per-section decisions matter for the user.
- If `total_drift_items <= 4`, only ONE AskUserQuestion call fires (no second batch).
- If `total_drift_items` is, e.g., 7, batches are `[1,2,3,4]` then `[5,6,7]` — two AskUserQuestion calls with 4 questions and 3 questions respectively.

---

## 9e — Marker Version Bump + Audit Log

After all decisions are processed, update the marker:

```bash
PLUGIN_VERSION=$(jq -r '.version' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json")
NEW_INIT_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# In-place sed update (preserves comments + ordering)
sed -i.bak \
  -e "s|^version: .*|version: \"${PLUGIN_VERSION}\"|" \
  -e "s|^init_at: .*|init_at: \"${NEW_INIT_AT}\"|" \
  "$MARKER"
rm -f "${MARKER}.bak"
```

Write the audit log to `${SCOPE_ROOT}/.bulwark/update-log-${timestamp}.yaml`:

```yaml
update_run:
  timestamp: "2026-05-09T22:30:00Z"
  marker_version_before: "1.2.0"
  marker_version_after: "1.3.0"
  drift_report: "${DRIFT_REPORT}"
  total_offered: 3
  applied: 2
  skipped: 1
  decisions:
    - artifact: "CLAUDE.md"
      anchor: "### Pre-WP Spec Drift Check (SD1 binding)"
      decision: applied
      timestamp: "2026-05-09T22:30:15Z"
    - artifact: ".claude/rules/rules.md"
      anchor: "## Spec Drift Rules (SD)"
      decision: applied
      timestamp: "2026-05-09T22:30:25Z"
    - artifact: ".claude/rules/rules.md"
      anchor: "### SD1: Pre-WP Spec Drift Check"
      decision: skipped
      timestamp: "2026-05-09T22:30:30Z"
```

---

## 9f — Final Summary

Present to the user:

```
Bulwark template update complete!

  Sections offered: ${total_offered}
  Applied:          ${applied}
  Skipped:          ${skipped}
  Marker:           ${marker_version_before} → ${marker_version_after}

Audit log: ${SCOPE_ROOT}/.bulwark/update-log-${timestamp}.yaml

What happens next:
  - The SessionStart drift hook will silent-skip on the next session
    if you applied everything.
  - If you skipped sections, the hook will re-flag the remainder; run
    /the-bulwark:init --update again when you want to revisit them.
  - The audit log records every decision for traceability.
```

---

## Error Handling

| Scenario | Handling |
|---|---|
| `MARKER` parse failure | STOP. Show problem line + suggest re-running `/the-bulwark:init` to regenerate marker. Do NOT proceed. |
| `update.sh` exit non-zero (e.g., canonical file missing, plugin root invalid) | STOP. Surface stderr to user. Do NOT proceed with applies. |
| `update.sh` exits 0 but report has 0 items | Present "up to date" message + exit cleanly. Marker is NOT bumped (no changes made). |
| `apply-section.sh` exits non-zero on any section | STOP loop immediately. Write audit log with partial-state warning naming the failing section. Do NOT continue with remaining sections (user file may be in inconsistent state — let user inspect). |
| User selects Skip on every offered section | Valid outcome. Write audit log normally with `applied: 0`. Marker is bumped (records that update was reviewed; no work needed). |
| User aborts via AskUserQuestion (cancel option) at 9c | Valid outcome. No marker bump, no audit log, exit cleanly. Drift hook continues to flag next session. |
| Marker shows `version` >= current plugin version (no upgrade needed) | Defensive: still run drift detection. If 0 items, present "up to date" and exit (skip marker bump since timestamps would just be cosmetic). |
| `${SCOPE_ROOT}/.bulwark/` directory not writable | STOP. Cannot write audit log or update marker. Show actionable error (chmod / chown guidance). |

---

## Edge Cases

### User has already-customized section

If the user's file has the same anchor with custom content, the diff (anchor-presence-only) does NOT flag it. UPDATE MODE never overwrites existing sections. Out-of-scope: deep-content diff (deferred to v1.3.0+ via `--deep-diff`).

### User has additional sections beyond canonical

One-way diff: canonical → user. User's custom additions are NEVER touched. They appear in the file alongside applied canonical sections.

### Canonical removed a section

Reverse drift (sections in user file but no longer in canonical) is flagged in the drift report's `removed:` array (if implemented in v1.2.0). Default behavior: report as informational, NEVER auto-remove. User-owned files are sacrosanct on the removal direction.

### Insertion position ambiguous

If the canonical position is between two existing sections that don't match the canonical neighbors (e.g., user reordered sections), `apply-section.sh` falls back to append-at-end-of-file. This is logged in the audit log as `decision: applied (fallback-position)`.

### Helper script is from a different plugin version than the marker says

Treat the helper script as authoritative (it ships with the current plugin version). The marker's plugin-version field is a "what was installed" record, not a "what to use".