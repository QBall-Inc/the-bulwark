# Repo Split: Private Dev + Public Distribution

## Overview

Split the current `QBall-Inc/the-bulwark` repo into:
- **Private**: `ashaykubal/the-bulwark-dev` — full development content
- **Public**: `QBall-Inc/the-bulwark` — user-facing plugin assets only

The local project folder (`/mnt/c/projects/the-bulwark/`) stays unchanged. Both remotes are configured on it.

## Public vs Private Assets

### PUBLIC (stays in QBall-Inc/the-bulwark)

| Path | Purpose |
|------|---------|
| `README.md` | Plugin documentation |
| `LICENSE` | MIT license |
| `plugin.json` | Plugin manifest |
| `skills/` | All plugin skills |
| `agents/` | All plugin agents |
| `hooks/` | Hook definitions (hooks.json) |
| `scripts/hooks/` | Hook shell scripts (enforce-quality.sh, inject-protocol.sh, etc.) |
| `scripts/init/` | Init scripts used by /init skill |
| `docs/` | Skill/agent READMEs, architecture docs |
| `lib/templates/` | Rules.md, CLAUDE.md, Justfile templates (used by /init) |
| `.gitignore` | Standard gitignore |

### PRIVATE (only in ashaykubal/the-bulwark-dev)

| Path | Purpose |
|------|---------|
| `sessions/` | Session handoff documents (98 sessions) |
| `plans/` | Task boards, task briefs, project plans |
| `tests/` | Test suites for AST scripts |
| `backup/` | File backups |
| `artifacts/` | Dev artifacts |
| `logs/` | Pipeline output logs |
| `templates/` | Dev templates (distinct from lib/templates) |
| `commands/` | Dev commands |
| `CLAUDE.md` | Bulwark's own dev CLAUDE.md |
| `Rules.md` | Bulwark's own dev Rules.md |
| `Justfile` | Bulwark's own dev Justfile |
| `package.json`, `package-lock.json` | Dev tooling |
| `tsconfig.json` | TypeScript config for dev |
| `starter-prompt.md` | Dev artifact |
| `report.html` | Dev artifact |
| `*.bak` | Backup files |
| `tmp/` | Temporary files |
| `.claude/` | Dev skills, agents, settings |
| `node_modules/` | Dependencies |
| `Infographics/` | Image assets (not committed) |

---

## Step 1: Create Private Repo

```bash
gh repo create ashaykubal/the-bulwark-dev --private --description "The Bulwark — development repo (private)"
```

## Step 2: Reconfigure Local Remotes

From your project folder:

```bash
cd /mnt/c/projects/the-bulwark

# Rename current origin (points to QBall-Inc/the-bulwark) to qball-public
git remote rename origin qball-public

# Add the private repo as origin (this becomes the default push target)
git remote add origin https://github.com/ashaykubal/the-bulwark-dev.git

# Push full history to the private repo
git push -u origin main
```

After this:
- `origin` = `ashaykubal/the-bulwark-dev` (private) — default for push/pull
- `qball-public` = `QBall-Inc/the-bulwark` (public) — explicit push only

### Git Desktop

After reconfiguring remotes in terminal, Git Desktop will automatically pick up the change. It shows the repo based on the folder path, not the remote name. You should see:

- The default remote switches to `the-bulwark-dev`
- Push button pushes to private repo by default
- To push to public: use **Repository > Push** and select `qball-public` from the remote dropdown, or use the sync script (Step 4)

If Git Desktop doesn't refresh automatically, remove and re-add the repo in Git Desktop (Repository > Remove, then File > Add Local Repository, point to `/mnt/c/projects/the-bulwark`).

## Step 3: Clean the Public Repo (Soft Clean)

This removes non-public files from the current tree with a single commit. History preserves old commits but the browsable tree only shows public assets.

```bash
cd /mnt/c/projects/the-bulwark

# Delete non-public files and directories from git tracking
# (does NOT delete them from your local filesystem — only from git)
git rm -r --cached \
  sessions/ \
  plans/ \
  tests/ \
  backup/ \
  artifacts/ \
  logs/ \
  templates/ \
  commands/ \
  CLAUDE.md \
  CLAUDE.md.bak \
  Rules.md \
  Rules.md.bak \
  Justfile \
  package.json \
  package-lock.json \
  tsconfig.json \
  starter-prompt.md \
  starter-prompt.md.bak \
  report.html \
  tmp/

# Commit the removal
git commit -m "Clean public repo: remove development-only files

Development content (sessions, plans, tests, configs) moved to private repo.
Public repo retains only user-facing plugin assets: skills, agents, hooks,
scripts, docs, and templates."

# Push ONLY to the public remote
git push qball-public main
```

**Important**: After this push, verify on GitHub that `QBall-Inc/the-bulwark` only shows public assets.

## Step 4: Prevent Future Leaks

After the soft clean, git tracks these files locally but they're removed from the public repo. To ensure future commits don't accidentally re-add them to the public remote, we use a sync script.

### Workflow: Daily Development

1. Work normally in `/mnt/c/projects/the-bulwark/`
2. Commit and push via Git Desktop — goes to `origin` (private repo) by default
3. All files (sessions, plans, tests, everything) are safely in the private repo

### Workflow: Publishing to Public Repo

When you want to update the public repo with new changes to public-facing files:

#### Option A: Sync Script (Recommended)

Create `scripts/sync-to-public.sh`:

```bash
#!/bin/bash
# sync-to-public.sh — Push public-facing files to QBall-Inc/the-bulwark
#
# Usage: ./scripts/sync-to-public.sh [--dry-run]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC_REMOTE="qball-public"
BRANCH="main"
WORKTREE_DIR="$REPO_ROOT/.public-worktree"

# Public files/directories to sync
PUBLIC_PATHS=(
  "README.md"
  "LICENSE"
  "plugin.json"
  "skills/"
  "agents/"
  "hooks/"
  "scripts/hooks/"
  "scripts/init/"
  "docs/"
  "lib/templates/"
  ".gitignore"
)

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[DRY RUN] No changes will be pushed."
fi

echo "=== Sync to public repo ==="

# Fetch latest from public remote
git -C "$REPO_ROOT" fetch "$PUBLIC_REMOTE" "$BRANCH" 2>/dev/null

# Create a temporary worktree from the public remote
if [[ -d "$WORKTREE_DIR" ]]; then
  git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_DIR" 2>/dev/null || rm -rf "$WORKTREE_DIR"
fi
git -C "$REPO_ROOT" worktree add "$WORKTREE_DIR" "$PUBLIC_REMOTE/$BRANCH" --detach

# Clean the worktree (remove everything except .git)
find "$WORKTREE_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy public files into the worktree
for path in "${PUBLIC_PATHS[@]}"; do
  src="$REPO_ROOT/$path"
  dest="$WORKTREE_DIR/$path"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    if [[ -d "$src" ]]; then
      rsync -a --delete "$src" "$(dirname "$dest")/"
    else
      cp "$src" "$dest"
    fi
  fi
done

# Check for changes
cd "$WORKTREE_DIR"
git add -A

if git diff --cached --quiet; then
  echo "No changes to publish."
else
  echo ""
  echo "Changes to publish:"
  git diff --cached --stat
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would commit and push the above changes."
  else
    read -p "Commit and push to $PUBLIC_REMOTE/$BRANCH? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      read -p "Commit message: " msg
      git commit -m "$msg"
      git push "$PUBLIC_REMOTE" HEAD:"$BRANCH"
      echo "Pushed to $PUBLIC_REMOTE/$BRANCH."
    else
      echo "Aborted."
    fi
  fi
fi

# Clean up worktree
cd "$REPO_ROOT"
git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true

echo "=== Done ==="
```

Make it executable:
```bash
chmod +x scripts/sync-to-public.sh
```

Add the worktree directory to .gitignore:
```
.public-worktree/
```

Usage:
```bash
# Preview what would be published
./scripts/sync-to-public.sh --dry-run

# Publish
./scripts/sync-to-public.sh
```

#### Option B: Git Desktop Manual Push

1. In Git Desktop, go to **Repository > Repository Settings > Remotes**
2. Confirm both remotes are listed: `origin` (private) and `qball-public` (public)
3. To push to public: open terminal from Git Desktop (Repository > Open in Terminal) and run:
   ```bash
   git push qball-public main
   ```

**Warning with Option B**: This pushes the entire current tree including private files. Only use this before Step 3 is done, or if you've set up proper .gitignore coverage. After Step 3, use the sync script (Option A) to ensure only public files reach the public repo.

## Step 5: Update .gitignore for Public Repo

The public repo's `.gitignore` should be updated to exclude development paths. This is already handled by the sync script (it only copies listed PUBLIC_PATHS), but as a safety net, add to `.gitignore`:

```
# Development-only (not in public repo)
sessions/
plans/
tests/
backup/
artifacts/
templates/
commands/
*.bak
starter-prompt.md
report.html
Justfile
tsconfig.json
package.json
package-lock.json
.public-worktree/
```

## Verification Checklist

After completing all steps:

- [ ] `git remote -v` shows both `origin` (private) and `qball-public` (public)
- [ ] `git push` (no args) goes to private repo
- [ ] GitHub: `ashaykubal/the-bulwark-dev` has all files (sessions, plans, tests, etc.)
- [ ] GitHub: `QBall-Inc/the-bulwark` shows only public assets (skills, agents, hooks, docs, README)
- [ ] Git Desktop default push goes to private repo
- [ ] `./scripts/sync-to-public.sh --dry-run` runs without errors
- [ ] Plugin still installable: `claude /plugin install the-bulwark@qball-inc`
- [ ] Plugin marketplace still resolves (marketplace.json unchanged)

## Rollback

If something goes wrong:

```bash
# Restore original remote setup
git remote remove origin
git remote rename qball-public origin
```

This puts everything back to the original state with `origin` pointing to `QBall-Inc/the-bulwark`.
