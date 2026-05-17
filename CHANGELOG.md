# Changelog

All notable changes to **The Bulwark** plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Public repository: [QBall-Inc/the-bulwark](https://github.com/QBall-Inc/the-bulwark)

---

## [Unreleased]

No unreleased changes at this time.

---

## [1.2.0] - 2026-05-17

Pre-release hardening bundle covering 13+ phases of post-launch reliability,
observability, governance, and tooling enhancements built between v1.1.0 and v1.2.0.

### Added

- **`plan-to-tasks` skill** — transforms `plan-creation` output into CLEAR-compatible execution structure (`tasks.yaml` + `workpackages/`). Supports parent/child plan linkage. *(P10.5)*
- **`spec-drift-check` skill** — audits work package briefs, plan docs, and memory entries for drift against current code state. Extracts claims, verifies each, emits PROCEED/STOP verdict with a structured verification log. *(P10.18)*
- **`SD1` (Spec Drift) rule** in `Rules.md` — mandatory pre-WP drift check before any new or resumed implementation. *(P10.18, P10.20)*
- **`init --update` mode** — guided drift remediation for stale `CLAUDE.md` / `Rules.md` sections. Batched/tabbed `AskUserQuestion` UX for ≥4 drifting sections. Parent/child anchor handling. *(P10.20, P10.24, P10.25)*
- **`check-template-drift.sh` SessionStart hook** — detects when project's `CLAUDE.md` or `Rules.md` have drifted from canonical templates and surfaces them for review. *(P10.20)*
- **`cleanup-review-registry.sh` SessionStart hook** — wipes stale review-accumulator state at session start so pipeline gating works across sessions. *(P10.16)*
- **`.bulwark/init-marker.yaml`** — written on first `/the-bulwark:init` run; consumed by `check-template-drift.sh` to scope drift detection. *(P10.20)*
- **`install-bun.sh`** — platform-aware, idempotent bun runtime installer (preparation for the evaluation framework). *(P10.11)*
- **Justfile recipes for evaluation framework** — `install-bun`, `verify-bun`, `eval-skill`, `eval-grade`, `eval`. *(P10.14)*

### Changed

- **`Stop` hook (`suggest-pipeline-stop.sh`)** — re-architected with per-file registry, file-type-aware pipeline routing, log-pattern suppression, and post-fix grace period. Reduces false-positive pipeline suggestions on doc-only or test-only changes. *(P10.12, P10.15, P10.19, P10.22)*
- **`PostToolUse` matcher** widened from `Write|Edit` to `Write|Edit|MultiEdit` — quality enforcement now applies to all three mutation tools. *(P10.16)*
- **`enforce-quality.sh`** — defensive `jq` fallback for malformed stdin, symlink rejection on accumulator write, atomic registry writes. *(P10.16)*
- **`code-review` skill** — hook output schema validation, file-type-aware pipeline mapping, grace-window coverage aggregation. *(P10.10, P10.19, P10.22)*
- **`test-audit` skill** — schema migration, grace-window coverage. *(P10.10, P10.22)*
- **`plan-creation` and `bulwark-brainstorm`** — Agent Teams mode synthesis-gate fixes (CC-ALL, Work-Complete, Re-Entry gates). Resolves premature synthesis exit in dual-mode pipelines. *(P10.6)*
- **`anthropic-validator`** — `SKILL.md` refactored to ≤500 lines, per-asset-type detail pushed to `references/`. Added `when_to_use` frontmatter for clearer triggering. *(P10.13)*
- **`bulwark-statusline`** — uses `--no-optional-locks` to avoid `.git/index.lock` contention. *(P10.16)*

### Fixed

- **`init --update`: parent/child anchor duplicate** — when both a top-level (`## Section`) and a nested (`### Subsection`) anchor drifted, the child was applied twice (once at EOF via fallback, once nested under parent). Fix suppresses child drift entries when their canonical parent is also drifting; parent's section extraction naturally brings nested children along. *(P10.25, BUG-S11-APPLY-001)*
- **`init --update`: CRLF handling** — `apply-section.sh` now uses POSIX `sub(/\r$/, "")` for cross-platform CRLF stripping (gawk + mawk + BSD awk on macOS). Replaces `RS = "\r?\n"` which is gawk-only. *(P10.24)*
- **`init --update`: early-exit on FALLBACK** — `apply-section.sh` no longer crashes on predecessor-lookup failure; cleanly falls through to EOF append path. *(P10.24)*
- **`update.sh` and `check-template-drift.sh`: parallel CRLF risk** — same POSIX `sub(/\r$/, "")` pattern applied to all three scripts. *(P10.24)*
- **`scripts/update.sh`: flag-prefix anchors** — `grep -Fxq --` end-of-options separator + herestring conversion prevent flag-shaped anchor names (`-n`, `-e`, `-E` prefixes) from being misinterpreted as command flags. *(P10.25, CR-SYN-001)*
- **`bulwark-statusline`**: 3 anthropic-validator findings on frontmatter clarity. *(S119)*

### Security

- **Path validation hardening** in `suggest-pipeline-stop.sh` and `cleanup-review-registry.sh` — symlink rejection on registry write, file-size caps, atomic-write guarantee. *(P10.15 self-test, S116-S117)*
- **Environment variable validation** in registry-emitting hooks (`SEC-005`, `SEC-007`). *(P10.15)*
- **`grep`/`sed`/`awk` end-of-options separator (`--`)** for user-controlled values, defending against flag-prefix attack vectors. *(P10.25)*

---

## [1.1.0] - 2026-04-21

P10.1 — Stop hook redesign + Justfile infrastructure rollout.

### Added

- **`--stage-only` flag** to `scripts/sync-to-public.sh` — stages the public asset set at `/tmp/bulwark-public-worktree` without committing or pushing, enabling local `claude --plugin-dir` testing before release.
- **Platform-aware `just` installer** (`scripts/install-just.sh`) invoked during `/the-bulwark:init`.
- **Toolchain smoke-run** (`scripts/toolchain-smoke-run.sh`) — verifies build/typecheck/lint recipes work end-to-end after init.

### Changed

- **Plugin manifest** (`.claude-plugin/plugin.json`) — adopted minimal schema; removed redundant `skills`/`agents`/`hooks` arrays now that Claude Code auto-discovers them. Resolves duplicate-hooks loading error reported by early users.
- **`Stop` hook output** — removed invalid `hookSpecificOutput` field that violated the Claude Code hook JSON schema. *(P10.10 root-cause-of-symptom)*

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

[Unreleased]: https://github.com/QBall-Inc/the-bulwark/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/QBall-Inc/the-bulwark/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/QBall-Inc/the-bulwark/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/QBall-Inc/the-bulwark/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/QBall-Inc/the-bulwark/releases/tag/v1.0.0
