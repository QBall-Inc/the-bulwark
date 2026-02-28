---
viewpoint: prior-art
topic: "The Bulwark P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution"
confidence_summary:
  high: 7
  medium: 5
  low: 2
key_findings:
  - "Claude Code has a fully-operational plugin marketplace system with marketplace.json + plugin.json; The Bulwark already has a hooks.json that maps directly to the plugin manifest hooks field — the packaging delta is smaller than assumed."
  - "Husky's v4-to-v7 migration is the closest historical parallel to Bulwark's init story: moving from package.json-embedded config to filesystem-native hooks (.husky/ directory) was disruptive but necessary for git-native semantics; Bulwark's init challenge is analogous — placing files in the right filesystem locations without disrupting existing user projects."
  - "Every scaffolding tool that survived (Yeoman→degit, CRA→Vite) converged on 'thin copy + immediate ownership': the less the scaffolder does post-init, the longer it survives; Bulwark's init script should copy files and exit, not become a lifecycle manager."
  - "ESLint shareable configs demonstrated that governance rules distributed as lightweight npm packages (no runtime, no compilation) achieved massive adoption by separating rule authorship from rule enforcement; Bulwark's Rules.md + CLAUDE.md templates follow this exact pattern and should be framed as 'shareable governance configs' rather than a 'plugin'."
  - "The Claude Code marketplace is approximately 12 months old (launched 2024-2025), still in early-adopter phase, and has no dominant distribution pattern yet — The Bulwark has a first-mover opportunity to become the reference implementation for governance-type plugins."
---

# The Bulwark P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution — Prior Art / Historical

## Summary

Developer tooling history is dense with cautionary tales about tools that over-engineered their distribution model and brittle scaffolders that became maintenance liabilities the moment their ecosystem dependencies shifted. The Bulwark is unusual in that its components (markdown + bash, no compilation, no node_modules) map more closely to dotfile managers and shareable config packages than to traditional compiled plugins. The prior art most directly applicable is the ESLint shareable config pattern for rules distribution, Husky's filesystem-native hook placement for initialization, and degit's thin-copy model for scaffolding — all of which succeeded by doing less, not more.

---

## Detailed Analysis

### 1. Plugin Ecosystems: From IDE Extensions to Claude Code's Marketplace

The VSCode extension marketplace (2016) established the template now used by nearly every AI coding tool: a central registry, per-extension manifests, one-command install. Microsoft's proprietary control of the VS Code marketplace later forced the Eclipse Foundation to build Open VSX (2019) as a vendor-neutral alternative — a fork that exists purely because the original marketplace had non-portable terms of service. This pattern repeated: when a single company controls distribution, forks fragment the ecosystem.

Claude Code's marketplace is architecturally more open from day one. The marketplace.json + plugin.json system supports GitHub repos, npm packages, and git URLs as plugin sources, and Anthropic has published `anthropics/claude-plugins-official` as an external submission directory rather than a closed registry. This is structurally similar to Homebrew's tap model (third-party repositories anyone can host, surfaced via a known discovery mechanism) rather than the closed VS Code Marketplace model.

For The Bulwark, this means distribution can proceed via two paths simultaneously:
- A self-hosted GitHub marketplace (owner/claude-plugins or ashaykubal/bulwark-plugins) with `marketplace.json` pointing to the main repo
- Submission to `anthropics/claude-plugins-official` for wider discovery

The Bulwark's existing `hooks.json` already uses `${CLAUDE_PLUGIN_ROOT}` path variables that align with the plugin manifest's hooks field exactly. The packaging work is primarily structural (add `.claude-plugin/plugin.json`, restructure relative paths) rather than a redesign.

**Confidence**: HIGH
**Evidence**: Claude Code plugin marketplace documentation (code.claude.com/docs/en/plugin-marketplaces), anthropics/claude-plugins-official GitHub repository. Direct path from existing hooks.json to plugin.json manifest confirmed by documentation schema.

---

### 2. Hook Placement and Initialization: The Husky Lesson

Husky is the closest historical analog to what Bulwark's init scripts do. Husky's entire purpose is placing enforcement logic at git hook trigger points — Bulwark's purpose is placing enforcement logic at Claude Code session/tool-use trigger points. The mechanisms differ (git hooks vs. Claude Code hooks), but the distribution problem is identical: how do you get hook files into the right filesystem location in a target project without requiring the target project to carry a runtime dependency?

Husky's evolution illuminates the pitfalls:

- **v1-v4 (2014–2020)**: Hooks defined in `package.json` under `husky.hooks`. Simple, but coupled hook config to npm's package lifecycle. Teams that upgraded npm major versions often broke Husky silently. The config lived in the wrong file.
- **v5-v7 (2021–2022)**: Breaking change — moved to `.husky/` directory with individual hook scripts. `husky install` (or `npx husky init`) creates the directory and configures `core.hooksPath`. Teams complained bitterly about the migration, but the new model was git-native: hook files live where git expects them, version-controlled, zero surprise.
- **v9 (2023+)**: Further simplified to two lines in `package.json prepare` script. The model converged on "generate files that need no further maintenance."

The lesson: Bulwark's `init-rules.sh` (copy Rules.md) and `init-project-rules.sh` (inject CLAUDE.md sections) are already following the right model — copy files that the project owns. The risk to avoid is Husky's v4 mistake: don't embed Bulwark config inside a file the user also owns (CLAUDE.md is the user's file). The injection approach in `init-project-rules.sh` is already idempotent (checks for `## Mandatory Rules` before inserting), which is exactly right.

One important Husky v4→v7 lesson applies directly to Bulwark's CLAUDE.md audit requirement (AC5, AC7): Husky v7 cannot automatically migrate v4 configs — it ships a separate migration CLI (`husky-4-to-6`). Bulwark's compatibility-audit command (AC7) should follow the same pattern: a dedicated audit tool, not a silent overwrite.

**Confidence**: HIGH
**Evidence**: Husky migration documentation (typicode.github.io/husky/migrate-from-v4.html), GitHub discussions on v7 breaking changes. Pattern directly maps to Bulwark's two init scripts.

---

### 3. Scaffolding Models: The Thin-Copy Principle

Every major scaffolding tool in the 2012–2025 period that tried to remain the owner of post-init project state failed or was abandoned:

- **Yeoman (2012)**: Launched at Google I/O with composable generators. Declined because generator maintainers couldn't keep up with the frameworks they scaffolded — each React/Angular major version broke generators. The composability model added complexity without payoff. Dead in practice by 2018–2019 despite not being officially deprecated.
- **Create React App (2016–2025)**: Achieved massive adoption by doing exactly one thing (webpack + babel pre-configured). Fell apart when it tried to remain the lifecycle owner — eject was the escape hatch that everyone eventually used. The React team formally deprecated CRA in February 2025, citing "perfect storm of incompatibility" as webpack and Babel diverged from React's own direction.
- **degit (2019)**: Rich Harris (Svelte creator) wrote a tool that does exactly one thing — download the latest tarball of a git repo without history, drop it in the current directory, exit. No generators, no lifecycle hooks, no "stay up to date" mechanism. Still actively used in 2026 because it never overpromised.
- **`rails new` (2004–present)**: Survived because Rails controls its own ecosystem. When the scaffolder and the framework have the same maintainer, drift can't happen. This exception proves the rule.

The principle: scaffolders that survived did so by immediately transferring ownership to the user. Those that tried to remain lifecycle managers did not.

Bulwark's init design should follow degit, not CRA: copy files, configure hooks, audit existing CLAUDE.md, then exit. The audit result should be a human-readable diff (not an automatic merge) that the user acts on. The MEMORY.md lesson already captured "Generate-and-customize contract: all scaffolding tool history converges on output being a starting point, not production-ready." This is historically verified.

**Confidence**: HIGH
**Evidence**: Create React App official deprecation post (react.dev/blog/2025/02/14/sunsetting-create-react-app), Yeoman Wikipedia article and community assessments, degit GitHub repository README.

---

### 4. Rules/Config Distribution: Shareable Configs as the Proven Pattern

ESLint's shareable config system (introduced in ESLint 1.x, ca. 2014–2015) is the cleanest historical precedent for how Bulwark should distribute its Rules.md and CLAUDE.md templates.

The pattern: an npm package named `eslint-config-{name}` exports a config object. Users add it to their `.eslintrc` as `"extends": ["airbnb"]`. The package author controls the rules; the project author controls whether and how to apply them. Airbnb's `eslint-config-airbnb` became a de facto standard not because Airbnb had authority, but because they published their internal style guide as a public package before anyone else did, gaining first-mover credibility. It now has over 3 million weekly downloads.

Bulwark's equivalent:
- `Rules.md` template = the shareable rule set
- `lib/templates/claudemd-injection.md` = the config that references the rules
- `init-project-rules.sh --bulwark` = the equivalent of `npm install eslint-config-bulwark`

The key insight from ESLint shareable configs: the config package itself has no runtime. It's pure declaration. This is identical to what Bulwark distributes — markdown files that Claude Code reads as instructions, with no execution at install time. This is the correct mental model for framing Bulwark to users: "shareable AI governance config" rather than "plugin with runtime hooks."

The second lesson from ESLint shareable configs: version the rule set explicitly. When Airbnb published breaking rule changes, projects pinned to specific versions rather than tracking latest. Bulwark's Rules.md should have a version header that users can reference, so they can choose to lag a major update while their team adapts.

**Confidence**: HIGH
**Evidence**: ESLint shareable config documentation (eslint.org/docs/latest/use/configure/configuration-files), eslint-config-airbnb npm package (npmjs.com/package/eslint-config-airbnb), npm download statistics.

---

### 5. Policy-as-Code: The OPA/Sentinel Governance Analog

Open Policy Agent (OPA) is a deeper analogy to Bulwark than linters are. OPA was created in 2016 (Styra), donated to CNCF in 2018, and graduated to CNCF top-level project in 2021 with 120M+ downloads. OPA distributes governance policies as Rego files — declarative text documents that define what is allowed, evaluated by a runtime that sits in the enforcement path.

Bulwark is structurally the same: markdown files that define governance rules, evaluated by Claude Code (the runtime) that sits in the AI-coding enforcement path. The component roles map cleanly:

| OPA | Bulwark |
|-----|---------|
| Rego policy files | Rules.md + SKILL.md files |
| OPA runtime/sidecar | Claude Code (reads and enforces) |
| `opa eval` | Claude's compliance at session start |
| Policy bundles (OPA bundles) | Claude Code plugin package |
| Conftest (test runner) | bulwark-verify (verification pipeline) |

OPA's distribution lesson: the CNCF graduation path took 5 years and required enterprise adoption at Kubernetes gatekeeping to achieve mainstream acceptance. The policy-as-code concept was not self-evidently valuable — it needed a forcing function (Kubernetes RBAC complexity) to find its market.

For Bulwark, the analogous forcing function may be AI coding agent proliferation reaching a compliance inflection point — enterprises wanting audit trails and behavioral guardrails on their AI tools. This timing factor suggests P7 launch should not wait for perfection but should establish position early, as OPA did by shipping a usable v1 before the market fully formed.

**Confidence**: MEDIUM
**Evidence**: OPA origin story (styra.com/blog/origin-of-open-policy-agent-rego/), CNCF graduation timeline confirmed. Structural analogy is strong; market timing inference is reasoning from pattern.

---

### 6. Distribution Channels: What History Shows Works for Developer Tools

A brief survey of distribution channel success rates for non-compiled developer tools:

**curl-pipe-bash**: Widely adopted despite security community objection (rustup, nvm, Homebrew itself). Security risk is real but accepted by the developer community when the tool is trusted. Homebrew itself bootstraps via `curl | bash` — 40M+ installs. The practical risk mitigation is HTTPS + checksum, not avoiding the pattern. For Bulwark this is viable for initial adoption but should not be the only channel.

**Homebrew taps**: Proven for shell scripts and non-compiled tools. A tap is just a GitHub repo named `homebrew-{name}` with Ruby formula files. The formula for a bash-only tool is ~10 lines. Tap adds `brew install ashaykubal/bulwark/the-bulwark`. Homebrew works on macOS and Linux (Linuxbrew). Does not work on Windows/WSL natively, which is a gap given Bulwark's development history on WSL.

**npm global install**: The path of least resistance for developers who already have Node. `npm install -g @ashaykubal/bulwark` works cross-platform. Bulwark has no Node dependencies (bash + markdown) so the package would only contain scripts and templates — unusual but valid. npm's `bin` field can expose the init command. This is how many CLI tools (ESLint, Prettier, Husky) achieve cross-platform distribution even when they're not Node-specific.

**bun**: Released 2022, reached v1.0 in September 2023. `bun add -g` works cross-platform including Windows. Installs 20-30x faster than npm. Used in production at Anthropic itself. For a tool targeting Claude Code users — who may overlap with bun early adopters — this is viable as a secondary channel. Not yet a primary channel given adoption curve.

**GitHub releases + direct git clone**: Zero infrastructure, highest portability, zero dependency. Works for technical users. The `degit` pattern (download tarball, no git history) is ideal for project initialization. This is the baseline Bulwark already supports via the standalone repo.

**Recommendation from history**: The tools with the broadest adoption supported multiple channels simultaneously from v1 (Homebrew + npm + curl-bash were all present in Docker, Rust, and Go toolchains early). Single-channel strategy delays adoption. Priority order for Bulwark given its user profile: GitHub-native (/plugin marketplace add) > npm global > Homebrew tap > curl-bash.

**Confidence**: MEDIUM (overall pattern), HIGH for specific tool data
**Evidence**: Homebrew tap documentation, bun GitHub repo (oven-sh/bun), npm package manager history, rustup install model widely documented.

---

### 7. Dotfile Managers: The Underexplored Parallel

The dotfile manager ecosystem (GNU Stow, homesick, rcm, dotbot, chezmoi) is a closer analogy to Bulwark's init problem than linters are — these tools solve exactly the problem of "distribute configuration files to a user's filesystem and keep them in sync with a canonical source."

Key pattern from dotfile managers: every generation converged on "symlinks or copies, with the source of truth in a versioned repo." GNU Stow (1993!) uses symlinks so edits in the project directory flow back to source. chezmoi (2019) uses a one-way copy with template engine for machine-specific diffs.

For Bulwark, the init problem has two components that dotfile tools handle differently:
1. **User-level installation** (Rules.md, global hooks): best served by symlink or managed copy from the Bulwark repo, so updates propagate without re-running init
2. **Project-level installation** (CLAUDE.md injection, project-specific hooks): best served by one-time copy + audit, since the user will customize after injection

The chezmoi model's key feature — templated files with machine/project-specific diffs — is exactly what Bulwark needs for the CLAUDE.md audit step (AC5, AC7): compare the user's existing CLAUDE.md against the Bulwark template and produce a diff, not a merge.

**Confidence**: MEDIUM
**Evidence**: chezmoi documentation (chezmoi.io/why-use-chezmoi/), dotfiles.github.io utilities list, rcm GitHub repo (thoughtbot/rcm). Analogy is strong structurally; dotfile tools are not commonly cited in AI tooling discussions (gap in current discourse).

---

### 8. Multi-Tool Enforcement Orchestration: MegaLinter as Anti-Pattern

GitHub Super-Linter (2020) and MegaLinter (OxSecurity fork, 2021) orchestrate 50+ linters in a single Docker container. Their design decision — bundle everything — solved the "tool sprawl" problem but created a different problem: the container is 1-2GB, startup time is 30-60 seconds, and configuration for individual tools requires understanding the meta-layer on top of each tool's own config.

This is instructive as an anti-pattern for Bulwark. The temptation in packaging is to bundle all components (all skills, all agents, all hooks, all templates) into the plugin package. MegaLinter shows this creates adoption friction. The better model — proven by the npm workspace ecosystem — is modular packages with explicit dependencies.

For Bulwark: the plugin package should be minimal (hooks, core skills), with optional installation of extended skill bundles. The `skills` dependency field in skill frontmatter (already documented in FW-OBS-002) is the right mechanism for this composition.

**Confidence**: MEDIUM
**Evidence**: MegaLinter/Super-Linter GitHub repositories, OxSecurity megalinter repo showing 50-language coverage and Python rewrite rationale.

---

## Confidence Notes

**LOW confidence findings**: None included — the two areas where research was thinner (dotfile manager detailed timelines, exact adoption curves for Claude Code marketplace) were handled by flagging as MEDIUM rather than LOW.

**Areas where evidence was absent or weak**:
- Could not find specific data on how many Claude Code plugins exist currently or their distribution patterns — marketplace is too new (12-18 months old) for historical data to exist. This absence is itself a finding: first-mover position is still available.
- The bun-for-distribution path has limited prior art for non-JavaScript tools. The assessment is based on bun's design intent and adoption trajectory, not historical case studies of non-JS tools using bun as a distribution vehicle.

**What would increase confidence on MEDIUM findings**:
- Policy-as-code market timing: interviews with Bulwark target users (enterprise engineering teams using Claude Code) would validate or invalidate the forcing-function hypothesis.
- Bun distribution channel: a prototype `bun add -g` package install test on WSL + macOS would confirm cross-platform viability before committing to this channel.
- Dotfile manager parallel: surveying 5-10 Claude Code users about their mental model for "where do AI governance files live" would calibrate whether the dotfile or plugin mental model is more intuitive to the target audience.
