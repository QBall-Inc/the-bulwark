---
viewpoint: first-principles
topic: "The Bulwark P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution"
confidence_summary:
  high: 8
  medium: 5
  low: 3
key_findings:
  - "The Bulwark is structurally 90% complete as a plugin — plugin.json, hooks/hooks.json, skills/, agents/ all exist. The gap is path canonicalization, not architecture."
  - "The four launch areas are not equally independent: Distribution must come last because it depends on what the installable artifact is, which depends on init design, which depends on governance file prep."
  - "Initialization is two distinct problems that must be separated: (1) installing the plugin into Claude Code and (2) configuring a project to use it. Conflating them forces users into unnecessary coupling."
  - "The governance files (Rules.md + CLAUDE.md) are a delivery mechanism problem, not a content problem — the slimming/centralization work is prerequisite to deciding how to deliver them."
  - "Distribution via a GitHub marketplace is mechanically sufficient for launch. Homebrew/npm are user-experience improvements, not functional requirements."
---

# The Bulwark P7 Launch — First Principles

## Summary

P7 reduces to one fundamental problem: how does a stranger get The Bulwark working in their project with minimal friction? The four areas (plugin manifest, initialization, governance files, distribution) are not parallel problems — they form a dependency chain. The plugin structure already exists and is nearly correct; the actual work is in initialization design, governance file preparation, and wrapping the result in a distribution mechanism that feels professional. The minimum viable launch requires exactly one thing: a user can run a single command and get enforcement hooks firing in their project.

---

## Detailed Analysis

### Focus Area 1: Plugin Manifest — What Is Actually Missing?

**Initial Assessment**

The plugin manifest problem initially appears to be about "creating a plugin.json with the right schema." But The Bulwark already has `.claude-plugin/plugin.json` with the correct structure:

```json
{
  "name": "the-bulwark",
  "description": "...",
  "version": "0.1.0",
  "commands": [],
  "agents": "agents/",
  "skills": "skills/",
  "hooks": "hooks/hooks.json",
  "author": { "name": "Ashay Kubal" }
}
```

The hooks file (`hooks/hooks.json`) uses `${CLAUDE_PLUGIN_ROOT}` correctly. The directory structure matches what the official docs require: `.claude-plugin/` at root with only `plugin.json` inside, `skills/`, `agents/`, `hooks/` all at plugin root.

**What Is Actually the Problem**

The real manifest problem is canonicalization. Two structural issues exist:

1. **Dual-directory confusion**: The project has both `skills/` (plugin source, correct) and `.claude/skills/` (dev copies). The `sync-hooks-for-dev.sh` pattern exists precisely because `.claude/settings.json` needs `${CLAUDE_PROJECT_DIR}` while `hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}`. This indirection is sound for development but must be documented clearly so a packager understands what ships and what doesn't. The `.claude/` directory is NOT part of the plugin artifact.

2. **Agents directory mismatch**: `plugin.json` declares `"agents": "agents/"` but `.claude/agents/` is the dev copy location. The root `agents/` directory should be the plugin's agent files (`.md` format per current Anthropic spec). A path audit of all 19 agents is needed to confirm they exist in `agents/` (root) and not exclusively in `.claude/agents/`.

3. **Section 5.6 applicability**: The original plan described commands as requiring backing shell scripts. In current Claude Code, skills and commands have merged — `.claude/commands/` and `.claude/skills/` are equivalent. The `commands: []` in `plugin.json` is correct (no separate commands needed). This is resolved.

**Confidence**: HIGH
**Evidence**: Official docs confirm: "Custom slash commands have been merged into skills." Plugin structure confirmed by examining `plugin.json`, `hooks/hooks.json` (which uses correct `${CLAUDE_PLUGIN_ROOT}` env var), and official plugin docs showing the exact same directory layout. The skills/commands merge eliminates the Section 5.6 concern.

---

### Focus Area 2: Initialization — Two Distinct Problems Being Conflated

**Initial Assessment**

The question "how does a new user get The Bulwark working in their project?" contains two conceptually separate problems that, if conflated, produce poor UX:

- **Problem A**: Getting The Bulwark installed into Claude Code (user-level, once per machine)
- **Problem B**: Configuring a specific project to use Bulwark governance (project-level, once per project)

**Why Separating These Matters**

The current init scripts (`init-rules.sh`, `init-project-rules.sh`) only address Problem B — they copy Rules.md and inject CLAUDE.md content into a target project. They assume the plugin is already installed. This is fine for the developer who installed from source, but a new user needs Problem A solved first.

Problem A (plugin installation) is now mechanically solved by Claude Code's `/plugin install` command. Once The Bulwark is in a marketplace, a user runs:

```
/plugin install the-bulwark@bulwark-marketplace
```

This installs at user scope (all projects) or project scope (this project). The plugin then fires its hooks automatically in any session where it's enabled.

Problem B (project configuration) involves:
1. **Governance files**: Delivering a project-specific `Rules.md` and `CLAUDE.md` content so Claude reads them
2. **Justfile**: Optional — providing a starter task runner config for the project's language (Node, Python, Rust)
3. **Compatibility audit**: Checking if the project already has CLAUDE.md or hooks that conflict with Bulwark's

**The AC6 Scope Choice (User-Level vs Project-Level) Is a Consequence, Not a Choice**

AC6 says "offer scope choice: user-level vs project-level installation." The distinction exists natively in Claude Code's `/plugin install` UI (user scope = all projects, project scope = this repo). The Bulwark does not need to implement this — it's built in. The initialization work is about what happens *after* installation, not about the installation mechanism itself.

**What the `init.sh` Script Needs to Do**

The unified `scripts/init.sh` (replacing `init-rules.sh` and `init-project-rules.sh`) should:

1. Detect if `Rules.md` already exists and offer backup/skip
2. Copy the slimmed `Rules.md` template
3. Detect if `CLAUDE.md` exists and audit it (does it already have `@Rules.md`?)
4. Inject the minimal CLAUDE.md injection (or create if missing)
5. Optionally: generate a starter Justfile from language templates
6. Emit a compatibility warning if conflicting hooks are detected in `.claude/settings.json`

This is not a complex script. The complexity is in the governance file content decisions (below), not the script mechanics.

**Progressive Initialization Is the Right Default**

The minimal path should be: install plugin → it works immediately (hooks fire, skills available). Governance file setup is a separate step the user can trigger with `/bulwark:init` or via `init.sh`. This avoids forcing users to run an init script before they get any value.

**Confidence**: HIGH
**Evidence**: Official docs confirm user-scope vs project-scope is a first-class Claude Code concept, handled by `/plugin install`'s scope selection UI. The init script files were read directly. AC7's "compatibility audit" requirement confirms the problem of pre-existing hooks needs to be handled.

---

### Focus Area 3: Rules.md and CLAUDE.md — A Delivery Mechanism Problem

**Initial Assessment**

The governance files problem initially looks like a content editing problem (slim Rules.md, move rules from CLAUDE.md). But the deeper issue is: what is the delivery contract for these files?

**The Core Constraint**

Claude Code loads `CLAUDE.md` and `Rules.md` as context at session start because they are in the project root. They are not loaded by the plugin directly — they must physically exist in the user's project. This means:

- The plugin can *deliver* governance files during init, but it cannot *own* them thereafter
- Once delivered, the files are the user's responsibility to maintain
- The plugin cannot auto-update them when it releases a new version

This creates a tension: The Bulwark wants governance consistency across users, but the files must live in user repos.

**The @mention Mechanism Changes the Calculus**

AC10 mentions: "at start of CLAUDE.md, @mention Rules.md so it auto-loads into context." In Claude Code, `@filename` in CLAUDE.md causes that file to be loaded into context at session start. This means:

- `CLAUDE.md` can be minimal (just `@Rules.md` + project-specific rules)
- `Rules.md` is the actual content document
- Updating the user's governance means updating `Rules.md`, which is a single-file operation

But this creates a new question: where does `Rules.md` live in the user's project? Options:
1. Project root (current pattern) — user must commit it, can drift from Bulwark's version
2. Plugin provides it at runtime via `${CLAUDE_PLUGIN_ROOT}/lib/templates/rules.md` and CLAUDE.md @mentions that path — user never has to manage it

Option 2 is cleaner (auto-updating with plugin updates) but requires verifying that `@${CLAUDE_PLUGIN_ROOT}/...` path syntax works in CLAUDE.md @mentions.

**What "Slimming" Actually Means**

The current `Rules.md` is 198 lines, `CLAUDE.md` is 203 lines. The CLAUDE.md contains two types of content:
- **Universal governance** (Binding Contract, Mandatory Rules referencing Rules.md) — should be in template
- **Bulwark project-specific rules** (OR1-4, SA1-6, conventions) — specific to Bulwark development, NOT appropriate for user project templates

The slimming problem is: separate what belongs in a user's project from what belongs in The Bulwark's own dev setup. The user-facing template should NOT include OR/SA rules — those are Bulwark-internal conventions. The user gets: Rules.md (CS/T/V/ID/TR/SC/SR rules) + minimal CLAUDE.md that @mentions it + a project-rules section for their own additions.

**Confidence**: MEDIUM
**Evidence**: The `@mention` behavior described in CLAUDE.md docs and the init scripts (which currently copy `lib/templates/rules.md`, not the project root `Rules.md`) confirm the two-file pattern. Whether `@${CLAUDE_PLUGIN_ROOT}/...` path works in @mentions requires verification — this is an assumption that would simplify delivery significantly if confirmed.

---

### Focus Area 4: Distribution — The Real Question Is What Artifact to Distribute

**Initial Assessment**

"Distribution" sounds like it requires choosing between Homebrew, npm, bun, or some other package manager. But the first-principles question is: what is the user actually installing?

The Bulwark is not a binary or a library — it is a directory of `.md`, `.json`, and `.sh` files. Package managers are designed for compiled artifacts with dependencies. Using them for The Bulwark is:

- **Homebrew**: Designed for compiled binaries. Using it for a git repo of markdown files requires a custom formula that clones and copies files. Possible but heavyweight.
- **npm**: Designed for JavaScript packages. Treating The Bulwark as an npm package is possible (`npm install -g @ashaykubal/the-bulwark`) but semantically wrong — there is no Node.js involved in the plugin itself.
- **bun**: Same semantic mismatch as npm, plus bun install for global scripts is a secondary use case.

**The Actually Correct Distribution Mechanism**

Claude Code's native plugin installation is the right distribution mechanism. A marketplace pointing to the GitHub repo is sufficient:

```
/plugin marketplace add ashaykubal/the-bulwark
/plugin install the-bulwark@ashaykubal
```

This:
- Is the intended Claude Code plugin distribution pattern
- Provides user-scope vs project-scope installation
- Supports version pinning and auto-updates
- Requires zero external tooling

**What Homebrew/npm Actually Solve**

The value proposition of Homebrew/npm is discoverability (searchable package registries) and familiar install commands (users know `brew install` or `npm install -g`). For the official Anthropic marketplace, discoverability is handled by the marketplace itself. For third-party distribution, a GitHub repo with a README is sufficient for early adoption.

The minimum viable distribution is: a public GitHub repo with a `.claude-plugin/marketplace.json` that lists the plugin. One command to add the marketplace, one to install.

**The Single-Command Dream (AC13)**

AC13 asks whether "plugin setup + initialization can be unified into the package installer." In Claude Code's model, this would require the plugin's `hooks/hooks.json` or a `settings.json` in the plugin root to trigger init on first load. A `SessionStart` hook could detect first-run (no `Rules.md` in project root) and prompt the user to run init. This is achievable within existing plugin mechanics.

**Confidence**: MEDIUM
**Evidence**: Official docs confirm GitHub-based marketplace is a first-class distribution pattern (`/plugin marketplace add owner/repo`). The npm/pip source types exist in marketplace.json plugin sources, but these are for plugin artifacts distributed as packages, not for the marketplace entry itself. No evidence that Homebrew formulae for Claude Code plugins exist as an established pattern.

---

### Focus Area 5: The Dependency Chain — What Must Be Done First

**Deepened Analysis (Second Pass)**

The initial decomposition treated the four areas as parallel. But examining the init script requirements and governance file decisions reveals a dependency chain:

```
Governance file prep (slimming Rules.md + CLAUDE.md template)
  → Init script design (init.sh needs final template content)
    → Plugin artifact finalization (plugin.json paths, version)
      → Marketplace creation (marketplace.json pointing to repo)
        → Distribution announcement (README, quickstart docs)
```

This has a concrete implication: **you cannot write the init script until you have decided what Rules.md and CLAUDE.md look like.** The init script is a delivery vehicle for those files. If the content changes after init.sh is written, the script must change too.

The P7.1 deliverables list reflects this correctly (Rules.md slimming is a deliverable alongside init.sh), but the risk is implementing them in the wrong order.

**The Minimal Viable Value Path**

From first principles, the minimum a user needs to get value from The Bulwark is:
1. Hooks firing (enforce-quality.sh on Write/Edit, inject-protocol.sh on SessionStart)
2. At least one user-invocable skill available (e.g., `/fix-bug`, `/code-review`)
3. A governance file (`Rules.md`) in their project that Claude reads

Item 1 is purely a plugin installation (plugin hooks fire automatically). Item 2 is automatic from plugin installation (skills in `skills/` are loaded). Item 3 requires init.

This means: hooks and skills require zero init work. Governance (Rules.md delivery) is the only mandatory init step. Everything else (Justfile, CLAUDE.md injection, compatibility audit) is progressively valuable but not mandatory for initial value.

**Confidence**: HIGH
**Evidence**: Plugin hooks fire automatically after installation — confirmed by official docs ("plugins can include a settings.json file at the plugin root to apply default configuration"). Skills are auto-available in the plugin namespace. Only governance files require explicit delivery to the project.

---

### Focus Area 6: Assumptions Requiring Validation

**Identified Assumptions**

Three assumptions in this analysis have not been verified and could change the decomposition:

1. **@mention path syntax for plugin-root files**: Whether `@${CLAUDE_PLUGIN_ROOT}/lib/templates/rules.md` works as an @mention in user CLAUDE.md. If it does, Rules.md can live in the plugin and never require copying to the user project. If it doesn't, the file must be copied during init (current approach). **Impact**: High — changes whether Rules.md delivery is a one-time or recurring concern.

2. **Agents directory contents**: Whether the root `agents/` directory contains the same 19 agents as `.claude/agents/`. If `agents/` is empty or stale, the plugin.json declaration `"agents": "agents/"` points to wrong/empty content. **Impact**: Medium — would require an agents sync step before packaging.

3. **Hook firing on installed plugins vs dev plugins**: Whether SessionStart hooks from installed plugins fire in the same way as dev (`--plugin-dir`) hooks, particularly the `once: true` behavior of `inject-protocol.sh`. The current settings.json has no `once: true` on the SessionStart hook. **Impact**: Medium — could cause governance protocol to not inject, or to inject every turn.

**Confidence for these assumptions**: LOW
**What would increase confidence**: Testing `@${CLAUDE_PLUGIN_ROOT}/...` in a test project, running `diff agents/ .claude/agents/`, and testing `--plugin-dir ./` with a session.

---

## Confidence Notes

**LOW confidence findings:**

1. **@mention path traversal**: Whether CLAUDE.md `@${CLAUDE_PLUGIN_ROOT}/...` syntax resolves at runtime is unverified. Anthropic docs describe @mention as a file-loading mechanism but do not specify whether environment variable paths are resolved. This is a critical assumption for the governance delivery design.

2. **`once: true` hook behavior in installed plugins**: The current `inject-protocol.sh` is registered without `once: true` in the dev settings.json (it was removed or never added to the project-level config). Whether the plugin-level hooks.json should include `once: true` for SessionStart to avoid repeated injection needs testing.

3. **npm/pip as distribution for non-code plugins**: The docs show npm/pip as plugin sources, but the semantic fit for a markdown/shell plugin is poor. The claim that "GitHub marketplace is sufficient" is directionally correct but the assertion that Homebrew/npm provide zero functional benefit is an inference — there may be discoverability or one-command-install user experience benefits that warrant the packaging complexity even for non-binary plugins.

**What would move these to MEDIUM or HIGH:**
- Test `@${CLAUDE_PLUGIN_ROOT}/...` in a real session
- Run `ls -la agents/` to confirm agent files exist there
- Survey 5 potential users on whether `brew install` vs `/plugin marketplace add` is a meaningful friction difference
