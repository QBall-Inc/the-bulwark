---
viewpoint: practitioner
topic: P7 Launch — Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution
confidence_summary:
  high: 6
  medium: 4
  low: 2
key_findings:
  - The Claude Code plugin marketplace is a first-class distribution path: a marketplace.json + plugin.json in a GitHub repo enables /plugin marketplace add owner/repo and single-command install — no homebrew or npm required for plugin-only distribution.
  - Plugin caching breaks path references outside the plugin directory — this is the most common silent failure practitioners hit post-install, and it requires restructuring files to be self-contained or using symlinks before publication.
  - The rules directory (.claude/rules/) is now the dominant team pattern for scaling instructions, with path-scoped frontmatter resolving the "slim vs comprehensive" tension; monolithic CLAUDE.md is actively discouraged by practitioners.
  - extraKnownMarketplaces has a confirmed bug in managed-settings.json (as of January 2026) — team-wide auto-enrollment requires the CLI workaround rather than a pure config-file approach.
  - Homebrew is viable for bash/markdown tools but introduces SHA256 hash + URL maintenance burden on every release; GitHub Actions automation is non-optional for sustainable homebrew tap maintenance.
---

# P7 Launch — Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution — Practitioner Perspective

## Summary

Claude Code's marketplace mechanism is now the primary distribution path for plugins, making homebrew/npm optional rather than required for initial launch. The two most consistently reported friction points are plugin self-containment (cache-copying breaks cross-directory references) and idempotent initialization across new vs. existing projects. Teams that have shipped Claude Code configurations converge on the modular rules directory pattern rather than a slim/comprehensive debate, and the extraKnownMarketplaces mechanism for team-wide auto-enrollment has a live bug that requires a CLI workaround.

## Detailed Analysis

### Plugin Packaging and the Marketplace Path

The Claude Code plugin marketplace is fully operational and is the lowest-friction distribution path for a bash/markdown plugin like The Bulwark. The mechanics are: create a `.claude-plugin/marketplace.json` at repo root listing plugin entries, each with a `source` (GitHub repo, relative path, npm package, or git URL). Users run `/plugin marketplace add owner/repo`, then `/plugin install plugin-name@marketplace-name`. The plugin manifest (`plugin.json`) in `.claude-plugin/` is optional — Claude Code auto-discovers components — but is required when you want explicit version tracking or custom component paths.

The critical practitioner trap is what Anthropic explicitly documents but teams still hit: plugins are copied to a cache at `~/.claude/plugins/cache` on install, not symlinked in place. Any file reference that traverses outside the plugin root (`../shared-utils`, root-level scripts) silently fails after installation. The standard workaround is symlinks that are followed during copy, or full restructuring so every dependency lives under the plugin root. For The Bulwark, this means verifying that hook scripts referenced as `${CLAUDE_PLUGIN_ROOT}/scripts/...` resolve correctly under the cached directory structure before shipping.

The `strict` field in plugin entries controls whether `plugin.json` is the authority or whether the marketplace entry drives everything. Default `strict: true` means both sources merge. For a mono-repo structure (one marketplace, multiple plugins), setting `strict: false` on plugin entries lets the marketplace operator define everything without each plugin needing its own manifest.

**Confidence**: HIGH
**Evidence**: Official Anthropic plugin-marketplaces documentation (code.claude.com/docs/en/plugin-marketplaces) explicitly warns about cache-copy behavior and path traversal restrictions. Multiple community plugins (claude-code-plugins-plus-skills, Trail of Bits skills repo) follow the self-contained structure pattern.

### Initialization — Unifying New and Existing Projects

The core pattern practitioners use for installer scripts that handle both new and existing projects is idempotency: check before acting, not act then check. The standard bash pattern is guard conditions on every operation (`mkdir -p` instead of `mkdir`, `if ! grep -q "pattern" file; then ... fi` before injecting into CLAUDE.md). Infrastructure-as-code tooling (Ansible) is often suggested as an alternative for complex cases, but for a markdown/bash plugin the bash idempotency pattern is sufficient.

For Claude Code specifically, the setup hook mechanism (`--init`, `--init-only`, `--maintenance` flags) provides a native path for initialization. A setup hook configured in `.claude/settings.json` runs before Claude boots, can install dependencies, check for existing configurations, and output results that Claude sees on startup. This is more reliable than a standalone bash script because it integrates with Claude Code's startup lifecycle.

The practitioner pattern observed at Trail of Bits uses a self-installing command (`/trailofbits:config`) that detects what is already present and skips completed steps. This slash-command approach has better UX than a raw bash script because users run it from within Claude Code, it can explain what it is doing, and it handles interactive confirmation naturally.

The unification question (one script for new and existing) is answered straightforwardly by idempotency: write one script that always checks state before modifying. The only divergence that requires separate paths is first-time configuration defaults vs. migration of existing configuration. A common solution is a `--force` or `--reset` flag for the existing-project case where you want to overwrite rather than skip.

**Confidence**: HIGH
**Evidence**: Idempotent bash script patterns are well-documented (arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/). Trail of Bits README confirms the self-installing slash command approach. Claude Code hooks reference (code.claude.com/docs/en/hooks) documents setup hook lifecycle.

### Rules and CLAUDE.md Preparation for Distribution

The practitioner consensus has moved clearly toward the modular rules directory over the monolithic CLAUDE.md. The problem is well-articulated: everything in one CLAUDE.md competes for the same priority level, which causes Claude to ignore instructions when context becomes noisy. The solution is `.claude/rules/*.md` with path-scoped frontmatter — files are auto-loaded with the same priority as CLAUDE.md, no explicit imports needed, and `paths:` frontmatter means API rules only apply when working on API files.

For plugin distribution, the injection question is how teams handle rules that a plugin wants to contribute to a project's CLAUDE.md. Two patterns are observed in the community:

1. **Additive append**: The init script appends a `@` import line to the project's CLAUDE.md pointing at the plugin's rules files. This keeps the project CLAUDE.md slim and makes plugin contribution explicit.
2. **Rules directory drop**: Plugin init copies or symlinks rule files into `.claude/rules/`, which are auto-loaded without any CLAUDE.md modification. This is less visible but more composable with other plugins.

The hooks-based context injection pattern (Trail of Bits uses PreToolUse hooks that inject rules at the moment of relevance rather than all at startup) is more powerful but harder to configure and is reported as overkill for most plugin use cases. Hook injection guarantees rules fire even under context pressure, while CLAUDE.md rules can be deprioritized as context window fills.

The "slim config for distribution vs. comprehensive config for power users" tension is resolved by shipping the modular structure: a minimal CLAUDE.md with project-level essentials, and rule files in `.claude/rules/` for topic-specific guidance. Users who want less load fewer rule files. This is more sustainable than maintaining two versions of the configuration.

**Confidence**: HIGH
**Evidence**: claudefa.st rules directory guide, official Claude Code memory documentation (code.claude.com/docs/en/memory). Trail of Bits configuration repo validates the hierarchical CLAUDE.md pattern at a production security team. DEV Community post on hooks-based guaranteed context injection confirms the hooks alternative for stricter enforcement.

### Distribution Channel — Homebrew vs. Marketplace vs. npm

The Claude Code native marketplace is now the primary answer for distribution of a Claude Code plugin. It does not require users to have Homebrew or npm. It integrates with Claude Code's update mechanism (`/plugin marketplace update`). It supports private repositories with token authentication. This is the channel that gets adoption from Claude Code users with the least friction.

Homebrew tap is the right secondary channel when targeting macOS developers who want system-level installation outside Claude Code (e.g., installing the bash scripts for use by other tools, or distributing an installer command). The friction practitioners consistently report with Homebrew taps for bash/markdown tools:

- Every release requires updating the formula's `url` and `sha256` fields. This is not automated by default.
- The `brew create` command generates outdated Ruby template code that must be corrected.
- Homebrew has no native update hook for script-only tools — versions have to be bumped manually.
- The solution all practitioners converge on: GitHub Actions workflow that triggers on release tags and auto-commits updated formula. Without this automation, Homebrew tap maintenance is reported as actively demotivating.

npm is the correct channel when the target audience already has Node.js and when the distribution is cross-platform. For a bash/markdown plugin it requires wrapping the install in a `postinstall` script, which works but feels semantically wrong. npm packaging for non-JS tools gets friction from developers who don't expect Claude Code plugins to come through npm.

The curl-pipe-bash pattern (`curl https://... | bash`) is reported as having the worst security optics in 2024-2025 even for developer tools. Teams that used it report pushback from security-conscious users and enterprises. Not recommended for initial launch.

**Confidence**: HIGH for marketplace path; MEDIUM for homebrew friction (based on practitioner blog posts, not The Bulwark's specific structure); LOW for curl-pipe-bash (based on community sentiment rather than measured data)
**Evidence**: Anthropic plugin marketplace documentation (code.claude.com/docs/en/plugin-marketplaces). Justin Searls practitioner post on Homebrew script distribution (justin.searls.co/posts/how-to-distribute-your-own-scripts-via-homebrew/) documents SHA update burden and GitHub Actions solution. Medium post "Distributing CLI Tools via npm and Homebrew" (medium.com/@sohail_saifi) confirms dual-channel pattern for broader reach.

### Known Bugs and Operational Caveats

Two live issues practitioners need to work around:

1. **`extraKnownMarketplaces` ignored in `managed-settings.json`** (GitHub issue #16870, reported January 2026, confirmed open): When added to `/etc/claude-code/managed-settings.json`, the configuration is completely ignored. Team members are not prompted to install the marketplace. Workaround: run `claude plugin marketplace add <url>` in a setup script or document it in team onboarding. Status: assigned but not resolved as of the date of this research.

2. **`extraKnownMarketplaces` not available in CI/CD headless mode** (GitHub issue #13096): The feature is interactive-only. CI pipelines using `claude -p` (print mode) cannot use marketplace-installed plugins. Workaround: use direct file paths or pre-install plugins before invoking headless mode.

Both issues affect teams who want fully automated, zero-touch onboarding. The interactive case (developer opens Claude Code in a new project) works correctly as documented.

**Confidence**: HIGH
**Evidence**: Both GitHub issues are confirmed open with multiple reporters. The managed-settings bug has an assigned owner but no fix as of January 2026.

## Confidence Notes

**LOW confidence findings:**

- "curl-pipe-bash has worst security optics": This is based on community discussions and practitioner preferences observed in blog posts, not measured adoption data. It is possible a well-documented curl installer with checksum verification would be accepted by the Claude Code community specifically.

- "npm is semantically wrong for non-JS tools": This is an inference from general community sentiment. The Bulwark's specific audience (Claude Code power users) may be more pragmatic about install channels. Testing with a small user group before committing to a distribution strategy would increase confidence here.

What would increase confidence on both: a survey or poll of the Claude Code community on preferred install channels, or observing adoption metrics from similar tools that have shipped through multiple channels simultaneously.
