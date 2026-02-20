#!/bin/bash
# Sync selected skills and agents from Bulwark to the Essential Agents & Skills repo.
# Usage: ./scripts/sync-essential-skills.sh [DEST_PATH]
#
# DEST_PATH defaults to ../essential-agents-skills (sibling directory).
# Only syncs skills listed in SKILLS array — Bulwark-internal skills are excluded.
#
# Post-sync transforms convert Bulwark-specific references (Justfile recipes,
# bulwark-statusline paths) to standalone equivalents. Source files are unchanged.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BULWARK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${1:-$BULWARK_ROOT/../essential-agents-skills}"

if [ ! -d "$DEST/.git" ]; then
  echo "Error: $DEST is not a git repository. Clone the repo first."
  exit 1
fi

# ============================================================
# 1. Sync skills (excluding build artifacts and tests)
# ============================================================

SKILLS=(
  anthropic-validator
  code-review
  bug-magnet-data
  test-audit
  test-classification
  mock-detection
  assertion-patterns
  component-patterns
  continuous-feedback
  create-skill
  session-handoff
  subagent-prompting
  subagent-output-templating
)

echo "=== Syncing skills ==="
mkdir -p "$DEST/skills"

for skill in "${SKILLS[@]}"; do
  if [ -d "$BULWARK_ROOT/skills/$skill" ]; then
    echo "  Syncing skills/$skill/"
    rsync -av --delete \
      --exclude 'node_modules' \
      --exclude '__tests__' \
      --exclude 'package-lock.json' \
      --exclude 'jest.config.ts' \
      "$BULWARK_ROOT/skills/$skill/" "$DEST/skills/$skill/"
  else
    echo "  WARNING: skills/$skill/ not found in Bulwark"
  fi
done

# ============================================================
# 2. Sync ez-statusline ecosystem (rebranded, self-contained)
# ============================================================
echo "=== Syncing ez-statusline ecosystem ==="

if [ -d "$BULWARK_ROOT/skills/bulwark-statusline" ]; then
  echo "  Syncing skills/bulwark-statusline/ -> skills/ez-statusline/"
  mkdir -p "$DEST/skills/ez-statusline"
  rsync -av --delete "$BULWARK_ROOT/skills/bulwark-statusline/" "$DEST/skills/ez-statusline/"
fi

if [ -f "$BULWARK_ROOT/lib/templates/statusline-default.yaml" ]; then
  echo "  Bundling statusline-default.yaml into skills/ez-statusline/templates/"
  mkdir -p "$DEST/skills/ez-statusline/templates"
  cp "$BULWARK_ROOT/lib/templates/statusline-default.yaml" "$DEST/skills/ez-statusline/templates/"
fi

if [ -f "$BULWARK_ROOT/scripts/statusline/statusline.sh" ]; then
  echo "  Bundling statusline.sh into skills/ez-statusline/scripts/"
  mkdir -p "$DEST/skills/ez-statusline/scripts"
  cp "$BULWARK_ROOT/scripts/statusline/statusline.sh" "$DEST/skills/ez-statusline/scripts/statusline.sh"
  chmod +x "$DEST/skills/ez-statusline/scripts/statusline.sh"
fi

# ============================================================
# 2b. Sync bulwark-* skills (rebranded, strip prefix)
# ============================================================
echo "=== Syncing bulwark-prefixed skills (stripped) ==="

BULWARK_SKILLS=(
  bulwark-research:research
  bulwark-brainstorm:brainstorm
)

for mapping in "${BULWARK_SKILLS[@]}"; do
  src="${mapping%%:*}"
  dest_name="${mapping#*:}"
  if [ -d "$BULWARK_ROOT/skills/$src" ]; then
    echo "  Syncing skills/$src/ -> skills/$dest_name/"
    mkdir -p "$DEST/skills/$dest_name"
    rsync -av --delete \
      --exclude 'node_modules' \
      --exclude '__tests__' \
      --exclude 'package-lock.json' \
      --exclude 'jest.config.ts' \
      "$BULWARK_ROOT/skills/$src/" "$DEST/skills/$dest_name/"
    # Rebrand: bulwark-{name} → {name} in SKILL.md
    if [ -f "$DEST/skills/$dest_name/SKILL.md" ]; then
      sed -i "s|bulwark-$dest_name|$dest_name|g" "$DEST/skills/$dest_name/SKILL.md"
      echo "  [rebrand] $dest_name SKILL.md: bulwark-$dest_name → $dest_name"
    fi
  else
    echo "  WARNING: skills/$src/ not found in Bulwark"
  fi
done

# ============================================================
# 3. Sync agents
# ============================================================

if [ -f "$BULWARK_ROOT/agents/bulwark-standards-reviewer.md" ]; then
  echo "  Syncing agents/bulwark-standards-reviewer.md -> agents/standards-reviewer.md"
  mkdir -p "$DEST/agents"
  cp "$BULWARK_ROOT/agents/bulwark-standards-reviewer.md" "$DEST/agents/standards-reviewer.md"
fi

if [ -f "$BULWARK_ROOT/agents/statusline-setup.md" ]; then
  echo "  Syncing agents/statusline-setup.md"
  mkdir -p "$DEST/agents"
  cp "$BULWARK_ROOT/agents/statusline-setup.md" "$DEST/agents/statusline-setup.md"
fi

# ============================================================
# 4. Sync tests and fixtures (separate from skills)
# ============================================================
echo "=== Syncing tests and fixtures ==="

# Test files: skills/test-audit/scripts/__tests__/ → tests/test-audit/
mkdir -p "$DEST/tests/test-audit"
rsync -av --delete \
  "$BULWARK_ROOT/skills/test-audit/scripts/__tests__/" "$DEST/tests/test-audit/"
echo "  Synced test files to tests/test-audit/"

# Fixtures: tests/fixtures/test-audit/ → tests/fixtures/test-audit/
mkdir -p "$DEST/tests/fixtures"
rsync -av --delete \
  "$BULWARK_ROOT/tests/fixtures/test-audit/" "$DEST/tests/fixtures/test-audit/"
echo "  Synced fixtures to tests/fixtures/test-audit/"

# ============================================================
# 5. Post-sync transforms
# ============================================================
echo "=== Applying post-sync transforms ==="

# --- 5a. AST recipe → npx tsx direct commands ---
AST_TRANSFORMS=(
  "just verify-count:npx tsx skills/test-audit/scripts/verification-counter.ts"
  "just skip-detect:npx tsx skills/test-audit/scripts/skip-detector.ts"
  "just ast-analyze:npx tsx skills/test-audit/scripts/data-flow-analyzer.ts"
  "just integration-mocks:npx tsx skills/test-audit/scripts/integration-mock-detector.ts"
)

AST_TRANSFORM_FILES=(
  "$DEST/skills/test-audit/SKILL.md"
  "$DEST/skills/test-audit/references/prompts/deep-mode-detection.md"
  "$DEST/skills/mock-detection/SKILL.md"
  "$DEST/skills/mock-detection/references/false-positive-prevention.md"
)

for file in "${AST_TRANSFORM_FILES[@]}"; do
  if [ -f "$file" ]; then
    for mapping in "${AST_TRANSFORMS[@]}"; do
      from="${mapping%%:*}"
      to="${mapping#*:}"
      if grep -q "$from" "$file" 2>/dev/null; then
        sed -i "s|$from|$to|g" "$file"
        echo "  [AST] ${file##*/}: '$from' → '$to'"
      fi
    done
  fi
done

# --- 5b. Prose "Justfile recipes" → "npx tsx" in test-audit ---
if [ -f "$DEST/skills/test-audit/SKILL.md" ]; then
  sed -i 's|via Justfile recipes|directly via npx tsx|g' "$DEST/skills/test-audit/SKILL.md"
  sed -i 's|invoked via Justfile recipes|invoked directly via npx tsx|g' "$DEST/skills/test-audit/SKILL.md"
  echo "  [prose] test-audit SKILL.md: Justfile references → npx tsx"
fi

# --- 5c. Generic just test/typecheck/lint → direct commands ---
# Covers test-audit, mock-detection, code-review, session-handoff examples, subagent-prompting examples
for file in "$DEST/skills/test-audit/SKILL.md" "$DEST/skills/mock-detection/SKILL.md"; do
  if [ -f "$file" ]; then
    sed -i 's|`just test`|`npx jest` (or your project test runner)|g' "$file"
    echo "  [generic] ${file##*/}: just test → generic"
  fi
done

if [ -f "$DEST/skills/code-review/SKILL.md" ]; then
  sed -i 's|`just typecheck`|`npx tsc --noEmit` (or your project typecheck command)|g' "$DEST/skills/code-review/SKILL.md"
  sed -i 's|`just lint`|your project lint command|g' "$DEST/skills/code-review/SKILL.md"
  sed -i 's|`just test`|`npx jest` (or your project test runner)|g' "$DEST/skills/code-review/SKILL.md"
  # Also handle bare (non-backtick) references in pipeline diagrams
  sed -i 's|Run: just typecheck|Run: npx tsc --noEmit|g' "$DEST/skills/code-review/SKILL.md"
  sed -i 's|Run: just lint|Run: your project lint command|g' "$DEST/skills/code-review/SKILL.md"
  echo "  [generic] code-review SKILL.md: just typecheck/lint/test → generic"
fi

# session-handoff and subagent-prompting example docs
for file in "$DEST/skills/session-handoff/references/examples.md" "$DEST/skills/subagent-prompting/references/examples.md"; do
  if [ -f "$file" ]; then
    sed -i 's|`just test`|`npx jest` (or your project test runner)|g' "$file"
    sed -i 's|`just lint`|your project lint command|g' "$file"
    sed -i 's|`just typecheck`|`npx tsc --noEmit` (or your project typecheck command)|g' "$file"
    sed -i 's|`just build`|your project build command|g' "$file"
    # Also handle non-backtick references in prose (e.g., "Add just build recipe")
    sed -i 's|just build|project build|g' "$file"
    sed -i 's|just test|project test runner|g' "$file"
    sed -i 's|just lint|project linter|g' "$file"
    sed -i 's|just typecheck|project typecheck|g' "$file"
    echo "  [generic] ${file##*/}: just recipes → generic"
  fi
done

# --- 5d. ez-statusline: bulwark-statusline → ez-statusline ---
EZFILE="$DEST/skills/ez-statusline/SKILL.md"
if [ -f "$EZFILE" ]; then
  sed -i 's|bulwark-statusline|ez-statusline|g' "$EZFILE"
  sed -i 's|/bulwark-statusline |/ez-statusline |g' "$EZFILE"
  echo "  [rebrand] ez-statusline SKILL.md: bulwark-statusline → ez-statusline"
fi

# --- 5e. continuous-feedback: bulwark-* references + just commands ---
CF_SKILL="$DEST/skills/continuous-feedback/SKILL.md"
if [ -f "$CF_SKILL" ]; then
  sed -i 's|`bulwark-research`|`research`|g' "$CF_SKILL"
  sed -i 's|`bulwark-brainstorm`|`brainstorm`|g' "$CF_SKILL"
  sed -i 's|just typecheck && just lint && just test|your project typecheck, lint, and test commands|g' "$CF_SKILL"
  echo "  [rebrand+generic] continuous-feedback SKILL.md: bulwark-* → stripped, just → generic"
fi
CF_PROPOSAL="$DEST/skills/continuous-feedback/templates/proposal-output.md"
if [ -f "$CF_PROPOSAL" ]; then
  sed -i 's|just typecheck && just lint && just test|your project typecheck, lint, and test commands|g' "$CF_PROPOSAL"
  echo "  [generic] continuous-feedback proposal-output.md: just → generic"
fi

# --- 5f. create-skill: strip Bulwark-specific rule IDs + project references ---
SC_FILES=(
  "$DEST/skills/create-skill/references/content-guidance.md"
  "$DEST/skills/create-skill/references/template-pipeline.md"
  "$DEST/skills/create-skill/references/decision-framework.md"
)
for file in "${SC_FILES[@]}"; do
  if [ -f "$file" ]; then
    # Strip parenthetical defect IDs: " (DEF-P4-005)" → ""
    sed -i 's| (DEF-P4-005)||g' "$file"
    # SC1-SC2 rule reference → generic
    sed -i 's|violates SC1-SC2|violates the skill'\''s instructions|g' "$file"
    # SA2/SA4 compliance → generic
    sed -i 's|(SA2/SA4 compliance)|(log-based handoff between stages)|g' "$file"
    # Bulwark project name → generic
    sed -i 's|Bulwark skills|Claude Code skills|g' "$file"
    # Bulwark-specific stats → generic
    sed -i 's|only 2 of 21 Bulwark skills use it|most skills work inline|g' "$file"
    echo "  [generic] ${file##*/}: Bulwark references → generic"
  fi
done

# --- 5g. Test file path transforms (standalone layout differs from Bulwark) ---
# In Bulwark: tests live at skills/test-audit/scripts/__tests__/
# In standalone: tests live at tests/test-audit/
# Each pattern is unique to its target line — no prefix collisions.
for testfile in "$DEST/tests/test-audit/"*.test.ts; do
  if [ -f "$testfile" ]; then
    # FIXTURES_ROOT: 4-parent chain + 'tests' is unique to this line
    #   '../../../../tests/fixtures/test-audit' → '../fixtures/test-audit'
    sed -i "s|'\.\.', '\.\.', '\.\.', '\.\.', 'tests', 'fixtures'|'..', 'fixtures'|" "$testfile"

    # TSX_BIN: '../node_modules' is unique to this line
    #   '../node_modules/.bin/tsx' → '../../skills/test-audit/scripts/node_modules/.bin/tsx'
    sed -i "s|__dirname, '\.\.', 'node_modules'|__dirname, '..', '..', 'skills', 'test-audit', 'scripts', 'node_modules'|" "$testfile"

    # SCRIPT_PATH: '..' followed by a .ts filename (unique to this line)
    #   '../script.ts' → '../../skills/test-audit/scripts/script.ts'
    sed -i "s|__dirname, '\.\.', '\([^']*\.ts\)'|__dirname, '..', '..', 'skills', 'test-audit', 'scripts', '\1'|" "$testfile"

    echo "  [paths] ${testfile##*/}: path constants updated"
  fi
done

echo ""
echo "=== Sync complete ==="
echo "Destination: $DEST"
echo ""
echo "Next steps:"
echo "  1. Review changes: cd $DEST && git status"
echo "  2. Commit: git add -A && git commit -m 'Sync from Bulwark'"
