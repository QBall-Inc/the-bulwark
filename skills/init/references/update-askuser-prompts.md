# UPDATE MODE — AskUserQuestion Prompt Templates

Canonical AskUserQuestion templates used by Stage 9 (UPDATE MODE) per artifact type. Drop-in copies for the orchestrator. Each template includes context substitutions in `${ ... }` form.

---

## Stage 9a — Backward-Compat: Marker Absent

Used when `${SCOPE_ROOT}/.bulwark/init-marker.yaml` does not exist (pre-v1.2.0 install or hand-rolled Rules.md project).

```text
question: "No init marker found at ${MARKER}. Was this project Bulwark-initialized?"
header: "Backward-compat check"
multiSelect: false
options:
  - label: "Yes — write marker for current state and proceed"
    description: |
      I'll generate a marker assuming the standard init layout
      (CLAUDE.md at scope root + .claude/rules/rules.md). You can
      then re-run --update to review template drift normally.
  - label: "No — this is a custom Rules.md project"
    description: |
      Skip --update; your Rules.md is hand-rolled and not derived
      from Bulwark templates. The SessionStart drift hook also
      silent-skips when the marker is absent (no false positives).
  - label: "Run /the-bulwark:init first"
    description: |
      If you intended to install Bulwark fully, run the fresh init
      flow (which writes the marker) instead of --update.
```

---

## Stage 9c — Pre-Flight Confirmation

Used after drift detection completes; summarizes scope before the batched per-section loop. The "Show full" inspection has moved here from per-section 9d (Option A batched UX per S125 P10.24) — Stage 9c is now the single canonical place to view complete section content before deciding.

```text
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

---

## Stage 9d — Per-Section Review (Batched, Markdown — CLAUDE.md / rules.md)

Used per drift item for markdown artifacts. **Batched call format**: the orchestrator builds an array of up to 4 such question objects and fires ONE AskUserQuestion call per batch (rendered as tabs in the UI). The template below is for ONE question within the batch.

```text
question: "${artifact.path} — Apply '${anchor}'?"
header: "Section ${i}/${total}"
multiSelect: false
options:
  - label: "Accept — apply this section"
    description: |
      Anchor: ${anchor}
      Excerpt:
      ${canonical_excerpt}

      Will be inserted at canonical position in ${artifact.path}
      (after the last existing section of the same family, or
      appended at end-of-file as fallback).
  - label: "Skip — don't apply this section"
    description: |
      Section is left out of ${artifact.path}. Next session, the
      SessionStart drift hook will flag it again until applied.
```

### Batched Call Example (4 markdown sections)

```text
questions:
  - { question: "CLAUDE.md — Apply 'Pre-WP Spec Drift Check'?",
      header: "Section 1/7", multiSelect: false,
      options: [<Accept template>, <Skip template>] }
  - { question: "Rules.md — Apply 'Spec Drift Rules (SD)'?",
      header: "Section 2/7", multiSelect: false,
      options: [<Accept template>, <Skip template>] }
  - { question: "Rules.md — Apply 'SD1: Pre-WP Spec Drift Check'?",
      header: "Section 3/7", multiSelect: false,
      options: [<Accept template>, <Skip template>] }
  - { question: "Rules.md — Apply 'SD2: Drift Verification Log'?",
      header: "Section 4/7", multiSelect: false,
      options: [<Accept template>, <Skip template>] }
```

A SECOND AskUserQuestion call then fires for sections 5/7, 6/7, 7/7 (3 questions, second batch). For totals ≤4, only ONE batch fires.

### Show-full inspection (moved to Stage 9c pre-flight)

There is NO inline "Show full" option in Stage 9d. Full per-section content inspection happens in Stage 9c (Pre-Flight) via the "Show full content for all sections first" option — that's the single canonical place to view complete content before deciding. Removing inline Show-full simplifies the batched UX (4 simultaneous decisions per call; no mid-batch re-prompt complexity).

---

## Stage 9d — Per-Section Review (Batched, Justfile — recipe)

Used per drift item for Justfile artifacts. Same batched call format as markdown variant — orchestrator builds an array of up to 4 question objects mixing markdown sections and Justfile recipes if both have pending drift. Template is for ONE question within the batch.

```text
question: "Justfile — Apply recipe '${recipe_name}'?"
header: "Recipe ${i}/${total}"
multiSelect: false
options:
  - label: "Accept — add recipe to Justfile"
    description: |
      Recipe: ${recipe_name}
      Body:
      ${recipe_body_excerpt}

      Will be inserted in canonical order in Justfile.
  - label: "Skip — don't add this recipe"
    description: |
      Recipe is left out of Justfile. Justfile will continue to lack
      ${recipe_name} until applied.
```

---

## Stage 9d — Per-Section Review (Batched, statusline JSON key)

Used per drift item for the statusline config in `~/.claude/settings.json` (or project equivalent). Same batched call format — orchestrator combines markdown / Justfile / statusline questions in one AskUserQuestion array up to 4 per call. Template is for ONE question within the batch.

```text
question: "statusline config — Add key '.statusLine.${key_name}'?"
header: "statusline key ${i}/${total}"
multiSelect: false
options:
  - label: "Accept — add key to statusline config"
    description: |
      Key: .statusLine.${key_name}
      Value:
      ${canonical_value}

      Will be inserted via jq into your settings.json
      (atomic write — your other settings are preserved).
  - label: "Skip — don't add this key"
    description: |
      Key is left out. Your statusline will not include
      ${key_name} until applied.
```

---

## Stage 9d — Helper-Script Failure Handling

If `apply-section.sh` exits non-zero on any section, STOP the loop and surface to the user. This is NOT a confirm-to-continue prompt; it's an inform-and-abort:

```text
question: "apply-section.sh failed on '${anchor}' (${artifact.path}). Loop aborted to prevent partial-state writes. How to proceed?"
header: "Apply failure — loop aborted"
multiSelect: false
options:
  - label: "Show stderr from apply-section.sh"
    description: |
      Display the helper's stderr output so I can diagnose the failure
      (file permissions, malformed canonical, position-ambiguity, etc.).
  - label: "Inspect the user file (${artifact.path}) manually"
    description: |
      Open ${artifact.path} for review. Some sections from earlier in
      the loop may have been applied successfully; this one failed.
      The audit log records what was applied vs aborted.
  - label: "Exit and triage"
    description: |
      Stop the run. The audit log at ${SCOPE_ROOT}/.bulwark/update-log-
      ${timestamp}.yaml records the partial state. Re-run --update
      after resolving the underlying issue.
```

---

## Style Conventions

- **Question** is one sentence ending in `?`. Keep under 250 chars when possible.
- **Header** is a short identifier (under 40 chars), suitable for chip/tag display.
- **Option labels** start with the action verb (Accept / Show full / Skip / Cancel). 1-5 words.
- **Option descriptions** are 2-4 lines. Include the consequence ("Next session, the hook will flag again until applied" is informative; "skips the section" is not).
- **Variable substitutions** use `${name}` form (matching shell syntax). The orchestrator interpolates before firing AskUserQuestion.

These templates are the contract — orchestrator MUST use them verbatim (with substitutions) for UX consistency. Custom phrasing risks confusing users across update runs.