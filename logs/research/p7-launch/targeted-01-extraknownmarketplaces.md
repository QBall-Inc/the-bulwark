# Targeted Research: `extraKnownMarketplaces` Bug Status (Issue #16870)

**Date**: 2026-02-28
**Researcher**: Claude Code sub-agent (Sonnet)
**Purpose**: P7 launch planning — determine viability of marketplace auto-enrollment as a distribution channel

---

## 1. Current Bug Status

**Issue #16870** — [`extraKnownMarketplaces` in `managed-settings.json` is ignored](https://github.com/anthropics/claude-code/issues/16870)

- **Status**: OPEN (as of 2026-02-28)
- **Filed**: January 8, 2026
- **Assignee**: whyuan-cc (Anthropic engineer)
- **Labels**: bug, area:core, has repro, platform:linux, api:bedrock
- **Activity**: Assignee requested clarification on exact config format (Jan 26). Reporter confirmed the config works when run manually via `claude plugin marketplace add`, ruling out config syntax as the issue.
- **Multiple confirmations**: At least two additional users (SHxKM, yuyuma) confirmed the bug independently in January 2026.

**Root cause (investigated)**: The `extraKnownMarketplaces` auto-enrollment mechanism is tied to the interactive trust dialog — when a user trusts a project folder, Claude Code processes project-defined marketplaces and prompts the user to install them. In `managed-settings.json`, this trust event trigger never fires, so the managed setting is silently ignored.

**Related issues discovered in the #16870 thread**:
- **#23978**: `extraKnownMarketplaces` with `directory` source type doesn't resolve relative paths
- **#26861**: Absolute paths silently fail for `directory` source type

**No fix has been merged as of 2026-02-28.** The CHANGELOG for versions 2.1.45 through 2.1.63 (covering January–February 2026) does not reference issue #16870 or a fix for managed-settings `extraKnownMarketplaces`.

---

## 2. Related Issue: Headless/CI Mode (#13096)

**Issue #13096** — [Support `extraKnownMarketplaces` in headless/print mode for CI/CD workflows](https://github.com/anthropics/claude-code/issues/13096)

- **Status**: CLOSED — NOT_PLANNED (closed February 5, 2026; locked February 13, 2026)
- **Outcome**: Anthropic closed this as not planned after 60 days of inactivity. No headless opt-in mechanism is coming for this path.

**Issue #13097** — [Clarify that `extraKnownMarketplaces` requires interactive trust dialog](https://github.com/anthropics/claude-code/issues/13097)

- This is a companion docs clarification issue. Status not definitively confirmed but suggests Anthropic views the interactive-trust requirement as by design, not a bug to fix.

---

## 3. How `extraKnownMarketplaces` Actually Works (What Does Work)

The feature functions correctly in **one specific path only**:

**Working path** — project-level `.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true
  }
}
```

When a team member opens Claude Code in a project with this config and **trusts the project folder**, they are prompted to install the marketplace and then the specified plugins. This is interactive-only; the trust dialog is the trigger.

**Broken path** — `/etc/claude-code/managed-settings.json` (Linux/WSL):
- The managed-settings file is read, but the `extraKnownMarketplaces` entries never trigger the trust dialog or prompt the user.
- Marketplaces do not appear in `/plugins`.
- This is the bug reported in #16870.

**Partially broken path** — headless/CI mode (`claude -p`):
- `extraKnownMarketplaces` from project settings is also ignored here because the trust dialog is bypassed.
- #13096 was closed NOT_PLANNED, so this will not be fixed.

**Changelog note — version 2.1.45**: Added support for reading `enabledPlugins` and `extraKnownMarketplaces` from `--add-dir` directories. This is an improvement for the `--add-dir` code path, but does not fix the managed-settings bug.

---

## 4. Documented Workarounds

### Workaround A: Project-level `.claude/settings.json` (RECOMMENDED — works today)

Place `extraKnownMarketplaces` in the project's `.claude/settings.json` instead of managed settings. Team members are prompted on first trust.

**Limitation**: Requires user interaction (trust dialog). Not zero-friction. Marketplaces are not pre-installed; users must respond to the prompt.

### Workaround B: Manual CLI install instructions

Provide team members with explicit install commands:
```bash
claude plugin marketplace add github:your-org/claude-plugins
claude plugin install bulwark@your-org-marketplace
```

Document these in onboarding materials. This is the most reliable distribution method given the current bug.

### Workaround C: GitHub Actions `plugin_marketplaces` input

For CI/CD workflows, use the official GitHub Action's `plugin_marketplaces` input parameter instead of relying on settings-based auto-enrollment.

### Workaround D: Pre-populate `~/.claude/plugins/known_marketplaces.json`

For managed machine environments, IT/DevOps can pre-configure the user-level marketplace registry directly before users launch Claude Code. This bypasses the trust dialog issue since the marketplace is already registered at the user level.

### Workaround E: `macOS plist` / `Windows Registry` for managed settings (v2.1.51+)

Version 2.1.51 added support for managed settings via macOS plist or Windows Registry as an alternative to `/etc/claude-code/managed-settings.json`. However, there is no evidence this resolves the `extraKnownMarketplaces` trigger mechanism bug — the root cause is the missing trust event, not the file format.

---

## 5. Impact on Bulwark's Distribution Strategy

### Summary Assessment

**Cannot rely on marketplace auto-enrollment via managed-settings.json.** The bug is open, unresolved, and has no ETA. Even if fixed, auto-enrollment through managed settings would only suit enterprise deployments with IT-managed machines — not the primary Bulwark user base (individual developers, small teams).

### Distribution Strategy Implications

| Channel | Status | Recommendation |
|---------|--------|----------------|
| `managed-settings.json` `extraKnownMarketplaces` | BROKEN (#16870) | Do not use as primary path. Note as known issue. |
| Project `.claude/settings.json` `extraKnownMarketplaces` | WORKS (interactive) | Use for team-level onboarding within a shared project repo |
| Manual CLI install | WORKS | Primary distribution path. Include in README and onboarding docs. |
| GitHub marketplace listing | WORKS | List on `anthropics/claude-plugins-official` if accepted |
| `enabledPlugins` in project settings | WORKS (after marketplace trust) | Can auto-enable plugins once marketplace is trusted |

### Recommended P7 Distribution Approach

1. **Primary path**: Manual install instructions in README:
   ```bash
   claude plugin marketplace add github:ashaykubal/bulwark-plugins
   claude plugin install bulwark@bulwark-plugins
   ```

2. **Team convenience path**: Include `extraKnownMarketplaces` in project `.claude/settings.json` so team members working in Bulwark projects get prompted on folder trust. This works today and covers the most common team scenario.

3. **Do NOT document managed-settings auto-enrollment** as a supported distribution path until #16870 is resolved. Doing so will cause user confusion when it silently fails.

4. **Monitor #16870** for resolution. If Anthropic fixes managed-settings processing, the distribution story becomes significantly easier for enterprise deployments.

---

## 6. Sources

- [GitHub Issue #16870 — extraKnownMarketplaces in managed-settings.json is ignored](https://github.com/anthropics/claude-code/issues/16870)
- [GitHub Issue #13096 — Support extraKnownMarketplaces in headless/print mode (CLOSED NOT_PLANNED)](https://github.com/anthropics/claude-code/issues/13096)
- [GitHub Issue #13097 — Clarify that extraKnownMarketplaces requires interactive trust dialog](https://github.com/anthropics/claude-code/issues/13097)
- [Claude Code Docs — Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code Docs — Settings reference](https://code.claude.com/docs/en/settings)
- [Claude Code CHANGELOG.md](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [Investigation Gist by alexey-pelykh — extraKnownMarketplaces CI/CD investigation](https://gist.github.com/alexey-pelykh/566a4e5160b305db703d543312a1e686)
- [Claude Code Releases](https://github.com/anthropics/claude-code/releases)
