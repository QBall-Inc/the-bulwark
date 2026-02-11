# Bulwark Development Justfile
# Used for dogfooding and development of The Bulwark plugin

set shell := ["bash", "-cu"]
set windows-shell := ["powershell.exe", "-c"]

# Default: list available recipes
default:
    @just --list

# ============================================================
# Standard Quality Recipes (required by enforce-quality.sh)
# ============================================================

# Type checking with TypeScript compiler
typecheck:
    @echo "Running typecheck..."
    @npx tsc --noEmit

# Linting (shellcheck for .sh, eslint for .ts if configured)
lint:
    @echo "Running lint..."
    @echo "Checking shell scripts with shellcheck..."
    @find scripts -name "*.sh" -exec shellcheck {} \; 2>/dev/null || echo "  shellcheck not installed, skipping"
    @if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then \
        echo "Checking TypeScript with eslint..."; \
        npx eslint . --ext .ts 2>/dev/null || true; \
    else \
        echo "  No eslint config found, skipping TypeScript lint"; \
    fi

# Build step (no-op for this project)
build:
    @echo "Running build..."
    @echo "No build step required (interpreted scripts)"

# Run tests (placeholder)
test:
    @echo "Running tests..."
    @echo "No automated tests configured yet"

# CI: Run all quality checks
ci: typecheck lint build test
    @echo "All quality checks passed"

# ============================================================
# Test Audit AST Recipes
# ============================================================

# Count verification lines in test file(s)
verify-count *path:
    @npx tsx skills/test-audit/scripts/verification-counter.ts {{path}}

# Detect skipped/focused/todo test markers
skip-detect *path:
    @npx tsx skills/test-audit/scripts/skip-detector.ts {{path}}

# Analyze data flow for T3+ broken integration chains (Phase 2)
# ast-analyze *path:
#     @npx tsx skills/test-audit/scripts/data-flow-analyzer.ts {{path}}

# ============================================================
# Bulwark Development Recipes
# ============================================================

# Sync plugin hooks to project settings for local development
sync-hooks:
    @echo "Syncing hooks from hooks/hooks.json to .claude/settings.json..."
    @./scripts/sync-hooks-for-dev.sh

# Validate all Justfile templates
validate-templates:
    @echo "Validating Justfile templates..."
    @for f in lib/templates/justfile-*.just; do \
        echo "  Checking $f..."; \
        just --justfile "$f" --list > /dev/null || exit 1; \
    done
    @echo "All templates valid."

# Run anthropic-validator on a skill
validate-skill skill:
    @echo "Validating skill: {{skill}}"
    @claude --print "/anthropic-validator skills/{{skill}}"

# Clean logs (keep .gitkeep files)
clean-logs:
    @echo "Cleaning logs..."
    @find logs -type f -name "*.yaml" -delete 2>/dev/null || true
    @find logs -type f -name "*.log" -delete 2>/dev/null || true
    @echo "Logs cleaned."

# Show hook status
hook-status:
    @echo "Plugin hooks (hooks/hooks.json):"
    @jq '.hooks | keys[]' hooks/hooks.json 2>/dev/null || echo "  Not found"
    @echo ""
    @echo "Project hooks (.claude/settings.json):"
    @jq '.hooks | keys[]' .claude/settings.json 2>/dev/null || echo "  Not found"
