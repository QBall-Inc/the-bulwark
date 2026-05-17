# Section-Anchor Diff Algorithm

This reference specifies the diff algorithm used by `update.sh` and the section-anchor extraction shared with `scripts/hooks/check-template-drift.sh`. Both consumers MUST use the same extraction rules — drift detection at SessionStart and drift-application via UPDATE MODE need to agree on what counts as a "section".

---

## What Counts as an Anchor?

A **section anchor** is a markdown header line that uniquely identifies a section within the file. The diff compares anchor PRESENCE between canonical and user file — content within sections is NEVER compared.

### Per-Artifact-Type Recipes

Different user-owned files use different anchor conventions. UPDATE MODE applies the appropriate extractor per artifact type (determined by file basename / extension).

#### CLAUDE.md (markdown)

Anchors: `^##\s+` (level-2) and `^###\s+` (level-3) headers. Header text after the `#` markers.

Examples:
```markdown
## Binding Contract                          # ANCHOR: "Binding Contract"
### Pre-WP Spec Drift Check (SD1 binding)    # ANCHOR: "Pre-WP Spec Drift Check (SD1 binding)"
#### Some sub-detail                         # NOT an anchor (level-4 too deep)
##### Deep nesting                           # NOT an anchor
```

Extraction:
```bash
grep -E '^(##|###) ' "$file" | sed -E 's/^#+[[:space:]]+//' | sort -u
```

Rationale: Bulwark's template structure uses ## for top-level sections and ### for rule IDs / subsections. Level-4+ headers are typically user-customization detail.

#### rules.md (markdown — Bulwark-style)

Same as CLAUDE.md: `^##\s+` and `^###\s+` headers. Rule IDs (e.g., `### SD1: Pre-WP Spec Drift Check`) are level-3 headers, so they extract as individual anchors. Section-level headers (e.g., `## Spec Drift Rules (SD)`) extract as level-2 anchors.

Same extraction command.

#### Justfile (just recipes)

Anchors: recipe names (lines matching `^[a-zA-Z][a-zA-Z0-9_-]*:`). Header text is the recipe name (everything before the first `:`).

Examples:
```just
typecheck:                    # ANCHOR: "typecheck"
    npx tsc --noEmit

eval-skill skill_path:        # ANCHOR: "eval-skill"
    bun scripts/eval/run-loop.ts {{skill_path}}

# This is a comment, not a recipe
```

Extraction:
```bash
grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:' "$file" | sed -E 's/^([a-zA-Z][a-zA-Z0-9_-]*):.*$/\1/' | sort -u
```

Rationale: Recipe-presence diff catches "canonical added a new recipe (e.g., `eval-grade`) the user's Justfile is missing". Recipe contents (the body lines after the `:`) are not compared.

#### Statusline config (JSON in `~/.claude/settings.json` or project equivalent)

Anchors: top-level keys in the `statusLine` object (if present). Extraction via jq:

```bash
jq -r '.statusLine | keys[]' "$file" 2>/dev/null | sort -u
```

Rationale: Statusline drift is rare (fixed schema). For v1.2.0, the diff just confirms the `statusLine` block exists in the user's settings.json with the canonical keys (e.g., `type`, `command`).

---

## Diff Algorithm

```bash
extract_anchors() {
  local file="$1"
  local artifact_type="$2"  # "markdown" | "justfile" | "statusline"
  case "$artifact_type" in
    markdown)
      grep -E '^(##|###) ' "$file" | sed -E 's/^#+[[:space:]]+//' | sort -u
      ;;
    justfile)
      grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:' "$file" | sed -E 's/^([a-zA-Z][a-zA-Z0-9_-]*):.*$/\1/' | sort -u
      ;;
    statusline)
      jq -r '.statusLine | keys[]' "$file" 2>/dev/null | sort -u
      ;;
  esac
}

CANONICAL_ANCHORS=$(extract_anchors "$CANONICAL_FILE" "$TYPE")
USER_ANCHORS=$(extract_anchors "$USER_FILE" "$TYPE")

# Sections in canonical but missing from user (one-way diff)
MISSING=$(comm -23 <(echo "$CANONICAL_ANCHORS") <(echo "$USER_ANCHORS"))
```

### `comm` Sort Invariant (CRITICAL)

`comm -23` requires both inputs to be sorted. The `sort -u` in `extract_anchors()` provides this. If `extract_anchors()` is ever modified to remove `sort -u`, `comm` will silently produce incorrect results — false-negative drift reports with no error.

**Defensive practice**: re-`sort` at the `comm` site OR add a comment-block contract pin at both the extractor and the consumer:

```bash
# Contract: extract_anchors returns SORTED output (sort -u in pipeline).
# comm -23 below depends on this; do not remove sort.
MISSING=$(comm -23 <(echo "$CANONICAL_ANCHORS") <(echo "$USER_ANCHORS"))
```

This contract is shared with `scripts/hooks/check-template-drift.sh` — the drift hook uses the same `extract_anchors` shape and the same `comm` invariant.

---

## Insertion Algorithm

`apply-section.sh` writes accepted sections into the user's file. Position-aware insertion follows these rules:

### Markdown (CLAUDE.md, rules.md)

1. **Same-family neighbor search**: scan canonical file for the section just BEFORE the target anchor (in canonical order). Find that same neighbor in the user file. Insert the new section immediately AFTER it.

   Example: canonical has `## Sub-Agent Rules (SA)` followed by `## Spec Drift Rules (SD)`. User has `## Sub-Agent Rules (SA)` but not `## Spec Drift Rules (SD)`. Insertion position: immediately after the last line of the user's `## Sub-Agent Rules (SA)` section.

2. **Section-end detection**: a section ends at the next same-or-shallower header (or end-of-file). For `## Spec Drift Rules (SD)`, end = next `## ` line. For `### SD1: ...`, end = next `## ` OR `### ` line.

3. **Append-at-end fallback**: if the same-family neighbor isn't found in the user file (user reordered, deleted, or never had it), append the new section at the end of the file. Log this as `decision: applied (fallback-position)` in the audit log.

4. **Atomic write**: write the new file content to a temp file, then `mv -f` over the user's file. NEVER edit-in-place; partial writes corrupt the file.

### Justfile

1. **Section-by-precedent**: insert before the first `[recipe-name]:` matching a known late-position recipe (e.g., `clean:`, `default:`). If no anchor recipe exists, append at end-of-file.

2. **Recipe blocks**: a recipe spans from its `name:` line until the next `^[a-zA-Z]` line (or EOF). Insert blank line between recipes for readability.

### Statusline JSON

1. **Key insertion via jq**: use `jq '.statusLine.<key> = <canonical-value>'` to add the missing key. Atomic write to temp + `mv`.

2. **Existing-key collision**: if user already has the key with a custom value, insertion is SKIPPED (the diff would have flagged this as already-present anyway since we're presence-only).

---

## What the Diff Does NOT Catch

By design, the algorithm is presence-only at the section level. It does NOT detect:

- **Content changes within an existing section** — if canonical updates the body of `## Binding Contract`, user's existing `## Binding Contract` is not flagged. (Future v1.3.0+ `--deep-diff` may add content equality.)
- **Section reorderings** — if user moved `## Coding Standards` after `## Testing Rules`, the diff sees both sections present and reports no drift.
- **Renamed sections** — if canonical renamed `## Sub-Agent Rules (SA)` to `## Subagent Orchestration Rules (SA)`, the diff sees the new anchor as missing AND treats the old anchor as user-customization (will not auto-remove). Result: user gets the new section ALONGSIDE their old one. This is a known v1.2.0 limitation; rename detection is deferred to v1.3.0+.
- **Deeply-nested headers** — `####` and `#####` are NOT anchors (per the level-2/level-3-only extractor). Sections at those depths are considered user-customization detail.

---

## Cross-References

- [update-mode.md](update-mode.md) — overall UPDATE MODE flow consuming this diff
- [update-askuser-prompts.md](update-askuser-prompts.md) — prompts presented per drift item
- `scripts/hooks/check-template-drift.sh` — SessionStart drift hook using the SAME extraction rules
- `scripts/update.sh` — implementation of the diff algorithm
- `scripts/apply-section.sh` — implementation of the insertion algorithm