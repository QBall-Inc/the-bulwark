# Changelog

All notable changes to **The Bulwark** plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Public repository: [QBall-Inc/the-bulwark](https://github.com/QBall-Inc/the-bulwark)

---

## [Unreleased]

No unreleased changes at this time.

---

## [1.3.0] - 2026-06-23

Fewer prompts, sharper reviews. This release cuts permission-prompt friction for
Bulwark's own bundled assets, makes the `code-review` skill language-aware so it
only runs checks that apply to each file, and adds an opt-in hook that
auto-approves tool calls scoped to the plugin's own files.

### Added

- **Opt-in permission-bypass hook** (`bulwark-permission-hook.sh`, PreToolUse) —
  auto-approves Read/Edit/Bash calls whose targets resolve **inside the plugin's
  own cache root**, so Bulwark's bundled skills and agents stop prompting for
  access to their own files. Off by default and never auto-installed; opt in per
  project via `bulwark-scaffold --with-permission-hook`. Path-traversal that
  spoofs a plugin prefix but escapes the root is blocked, and any target outside
  the plugin cache (for example `/etc/passwd` or a network `curl`) still prompts
  normally. Documented as a separate, default-off hook — the always-on set
  remains eight hooks.
- **`bulwark-scaffold --with-permission-hook` flag** — installs the opt-in
  permission hook at project scope during scaffolding.
- **Universal per-language `code-review` recipes** across all eight Justfile
  templates and the root Justfile — `typecheck-py`, `lint-py`, `validate-json` /
  `validate-yaml`, and `shellcheck`. Each recipe degrades gracefully: it skips
  and exits 0 when the underlying tool is absent, and propagates the tool's exit
  status when present.

### Changed

- **`code-review` skill is now language-aware** — it detects each changed file's
  language and gates review sections via a Language Applicability table, so it
  runs only the checks relevant to the files under review instead of assuming a
  single stack.
- **`allowed-tools` declared on all 30 skills; `tools` audited on all 15
  agents** — every skill now pre-authorizes exactly the tools it needs, removing
  routine permission prompts during normal skill execution. (`allowed-tools`
  *pre-authorizes*, it does not restrict; `disallowed-tools` remains the
  restriction field.)

---

## [1.2.1] - 2026-05-17

Hotfix for SessionStart and Stop hooks failing with `Permission denied` on
fresh v1.2.0 installs.

### Fixed

- **Hook scripts shipped without executable bit** — three hooks
  (`cleanup-review-registry.sh`, `check-template-drift.sh`,
  `suggest-pipeline-stop.sh`) were stored in the v1.2.0 tree at mode `100644`
  instead of `100755`, causing the Claude Code plugin runtime to fail with
  `Permission denied` on direct execve. Five additional non-hook scripts shared
  the same defect but were invoked via `bash <path>` wrappers and unaffected
  at the user level. Root cause: the release sync workflow ran with
  `core.fileMode = false` (inherited from the WSL/NTFS development repo via
  worktree config sharing), causing `git add` to stage new `.sh` files at the
  default mode `100644`. *(GitHub issue [#1](https://github.com/QBall-Inc/the-bulwark/issues/1))*
- **`sync-to-public.sh` mode preservation** — the publish script now scans
  every tracked `.sh` file in the staging worktree and calls
  `git update-index --chmod=+x` on each, bypassing `core.fileMode` entirely.
  Idempotent and safe under any local git config.

### Upgrade notes

For users on a fresh v1.2.0 install affected by the hook failure, upgrading
to v1.2.1 via `/plugin update the-bulwark@qball-inc` (or a fresh install) will
restore correct hook execution. No project-level changes required.

---

## [1.2.0] - 2026-05-17

Hardening and observability bundle covering post-launch reliability,
governance, and tooling enhancements built between v1.1.0 and v1.2.0.

### Added

- **`plan-to-tasks` skill** — transforms `plan-creation` output into an execution-ready structure (`tasks.yaml` + `workpackages/`). Supports parent/child plan linkage.
- **`spec-drift-check` skill** — audits work package briefs, plan docs, and memory entries for drift against current code state. Extracts claims, verifies each, emits PROCEED/STOP verdict with a structured verification log.
- **`SD1` (Spec Drift) rule** in `Rules.md` — mandatory pre-WP drift check before any new or resumed implementation.
- **`init --update` mode** — guided drift remediation for stale `CLAUDE.md` / `Rules.md` sections. Batched/tabbed `AskUserQuestion` UX for ≥4 drifting sections. Parent/child anchor handling.
- **`check-template-drift.sh` SessionStart hook** — detects when project's `CLAUDE.md` or `Rules.md` have drifted from canonical templates and surfaces them for review.
- **`cleanup-review-registry.sh` SessionStart hook** — wipes stale review-accumulator state at session start so pipeline gating works across sessions.
- **`.bulwark/init-marker.yaml`** — written on first `/the-bulwark:init` run; consumed by `check-template-drift.sh` to scope drift detection.
- **`install-bun.sh`** — platform-aware, idempotent bun runtime installer (preparation for the evaluation framework).
- **Justfile recipes for evaluation framework** — `install-bun`, `verify-bun`, `eval-skill`, `eval-grade`, `eval`.

### Changed

- **`Stop` hook (`suggest-pipeline-stop.sh`)** — re-architected with per-file registry, file-type-aware pipeline routing, log-pattern suppression, and post-fix grace period. Reduces false-positive pipeline suggestions on doc-only or test-only changes.
- **`PostToolUse` matcher** widened from `Write|Edit` to `Write|Edit|MultiEdit` — quality enforcement now applies to all three mutation tools.
- **`enforce-quality.sh`** — defensive `jq` fallback for malformed stdin, symlink rejection on accumulator write, atomic registry writes.
- **`code-review` skill** — hook output schema validation, file-type-aware pipeline mapping, grace-window coverage aggregation.
- **`test-audit` skill** — schema migration, grace-window coverage.
- **`plan-creation` and `bulwark-brainstorm`** — Agent Teams mode synthesis-gate fixes (CC-ALL, Work-Complete, Re-Entry gates). Resolves premature synthesis exit in dual-mode pipelines.
- **`anthropic-validator`** — `SKILL.md` refactored to ≤500 lines, per-asset-type detail pushed to `references/`. Added `when_to_use` frontmatter for clearer triggering.
- **`bulwark-statusline`** — uses `--no-optional-locks` to avoid `.git/index.lock` contention.

### Fixed

- **`init --update`: parent/child anchor duplicate** — when both a top-level (`## Section`) and a nested (`### Subsection`) anchor drifted, the child was applied twice (once at EOF via fallback, once nested under parent). Fix suppresses child drift entries when their canonical parent is also drifting; parent's section extraction naturally brings nested children along.
- **`init --update`: CRLF handling** — `apply-section.sh` now uses POSIX `sub(/\r$/, "")` for cross-platform CRLF stripping (gawk + mawk + BSD awk on macOS). Replaces `RS = "\r?\n"` which is gawk-only.
- **`init --update`: early-exit on FALLBACK** — `apply-section.sh` no longer crashes on predecessor-lookup failure; cleanly falls through to EOF append path.
- **`update.sh` and `check-template-drift.sh`: parallel CRLF risk** — same POSIX `sub(/\r$/, "")` pattern applied to all three scripts.
- **`scripts/update.sh`: flag-prefix anchors** — `grep -Fxq --` end-of-options separator + herestring conversion prevent flag-shaped anchor names (`-n`, `-e`, `-E` prefixes) from being misinterpreted as command flags.
- **`bulwark-statusline`**: 3 anthropic-validator findings on frontmatter clarity.

### Security

- **Path validation hardening** in `suggest-pipeline-stop.sh` and `cleanup-review-registry.sh` — symlink rejection on registry write, file-size caps, atomic-write guarantee.
- **Environment variable validation** in registry-emitting hooks.
- **`grep`/`sed`/`awk` end-of-options separator (`--`)** for user-controlled values, defending against flag-prefix attack vectors.

---

## [1.1.0] - 2026-04-21

Stop hook redesign + Justfile infrastructure rollout.

### Added

- **`--stage-only` flag** to `scripts/sync-to-public.sh` — stages the public asset set at `/tmp/bulwark-public-worktree` without committing or pushing, enabling local `claude --plugin-dir` testing before release.
- **Platform-aware `just` installer** (`scripts/install-just.sh`) invoked during `/the-bulwark:init`.
- **Toolchain smoke-run** (`scripts/toolchain-smoke-run.sh`) — verifies build/typecheck/lint recipes work end-to-end after init.

### Changed

- **Plugin manifest** (`.claude-plugin/plugin.json`) — adopted minimal schema; removed redundant `skills`/`agents`/`hooks` arrays now that Claude Code auto-discovers them. Resolves duplicate-hooks loading error reported by early users.
- **`Stop` hook output** — removed invalid `hookSpecificOutput` field that violated the Claude Code hook JSON schema.

### Fixed

- **npm tarball size** reduced ~120x by adding `Infographics/` to `.npmignore`. Earlier `1.0.0` tarballs erroneously bundled high-resolution image assets.
- **`sync-to-public.sh` `--delete` bug** — `rsync -a --delete "$src" "$(dirname "$dest")/"` for top-level directories resolved to the worktree root and could wipe `.git`. Fixed with `mkdir -p "$dest"` + trailing-slash convention.
- **WSL symlink resolution** in `sync-to-public.sh` — `pwd -P` resolves symlinked working directories correctly.
- **`init` skill env-var reference** — `${CLAUDE_PLUGIN_ROOT}` (canonical) replaces `$CLAUDE_PLUGIN_DIR` (does not exist in Claude Code).

---

## [1.0.1] - 2026-03-02

Same-day post-launch documentation polish.

### Changed

- Rollout documentation updates (no behavioral changes).

---

## [1.0.0] - 2026-03-02

Initial public release.

### Added

- **28 skills** spanning product/strategy, code quality, project setup, and meta orchestration.
- **15 single-purpose sub-agents** for fix validation, plan creation, product ideation, and statusline configuration.
- **6 hooks**:
  - `enforce-quality.sh` (PostToolUse) — runs `just typecheck`, `just lint`, `just build` after every Write/Edit on code files.
  - `inject-protocol.sh` (SessionStart) — injects governance protocol + `Rules.md` into every session.
  - `cleanup-stale.sh` (SessionStart) — purges files older than 10 days from `logs/` and `tmp/`.
  - `suggest-pipeline-stop.sh` (Stop) — surfaces relevant review/audit pipelines based on session activity.
  - `track-pipeline-start.sh` (SubagentStart) / `track-pipeline-stop.sh` (SubagentStop) — pipeline observability.
- **`Rules.md` governance framework** — Coding Standards (CS1-CS4), Testing Rules (T1-T4), Verification Rules (V1-V4), Issue Debugging (ID1-ID3), Orchestrator Rules (OR1-OR3), Sub-Agent Rules (SA1-SA6), Skill Compliance Rules (SC1-SC3).
- **`/the-bulwark:init` skill** — guided project initialization with `CLAUDE.md` generation, `Rules.md` installation, and optional Justfile scaffolding, LSP setup, and statusline configuration.
- **Distribution channels**: npm (`@qball-inc/the-bulwark`) and plugin marketplace (`QBall-Inc/plugins-market`).

---

[Unreleased]: https://github.com/QBall-Inc/the-bulwark/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/QBall-Inc/the-bulwark/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/QBall-Inc/the-bulwark/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/QBall-Inc/the-bulwark/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/QBall-Inc/the-bulwark/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/QBall-Inc/the-bulwark/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/QBall-Inc/the-bulwark/releases/tag/v1.0.0
