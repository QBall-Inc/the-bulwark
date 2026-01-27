# Bulwark Development Justfile
# Used for dogfooding and development of The Bulwark plugin

set shell := ["bash", "-cu"]
set windows-shell := ["powershell.exe", "-c"]

# Default: list available recipes
default:
    @just --list

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
