---
role: technical-architect
topic: "P7.1 Launch: Plugin Manifest, Initialization, and Distribution"
recommendation: proceed
key_findings:
  - "Init pipeline must use a two-layer composition: mandatory atomic scripts (init-rules.sh, init-project-rules.sh) orchestrated by a new init.sh, with skill-delegation for optional steps — do NOT absorb bulwark-scaffold or setup-lsp logic"
  - "CN1/CN2 conditional inclusion is best solved by splitting rules into two files: lib/templates/rules-core.md (always installed) and lib/templates/rules-cn.md (LSP opt-in only) — aligns with .claude/rules/ modular auto-load pattern"
  - "Cleanup script (AC17) requires SessionStart new-session detection — use a session marker file strategy (write .session-id on start, skip cleanup if marker matches current session) to distinguish new session vs resume vs compact"
  - "bulwark-scaffold delegation (not absorption) is the correct pattern — init.sh invokes it as a recommended step, not as an embedded substep"
  - "Distribution: marketplace is the correct primary path; homebrew/npm are valid secondary options but add maintenance burden — recommend marketplace-first with homebrew tap as bonus milestone"
---

# P7.1 Launch — Technical Architect

## Summary

The Bulwark plugin architecture is structurally sound and close to launch-ready. The core architectural question for P7.1 is not whether to build but HOW to compose the init pipeline: the answer is strict script atomicity (CS1) with skill-delegation for optional steps. The five design questions each have clear architectural answers that align with existing patterns, but three carry implementation complexity worth flagging: CN rule conditional inclusion, cleanup new-session detection, and the agent directory structure that currently exposes test agents to users.

## Detailed Analysis

### Architectural Approach

#### 1. Init Pipeline Composition

**PROPOSE:** A three-tier init architecture:

```
init.sh (orchestrator)
  ├── MANDATORY: init-rules.sh → .claude/rules/rules-core.md
  ├── MANDATORY: init-rules-cn.sh → .claude/rules/rules-cn.md [if LSP opt-in]
  ├── MANDATORY: init-project-rules.sh → CLAUDE.md injection
  ├── RECOMMENDED: /setup-lsp delegation (prompts user, skill handles it)
  ├── RECOMMENDED: /bulwark-scaffold delegation (prompts user, skill handles it)
  └── OPTIONAL: /bulwark-statusline delegation (prompts user if desired)
```

**VALIDATE (codebase check):**
- `init-rules.sh` is atomic (40 lines, single responsibility: copy rules.md)
- `init-project-rules.sh` is atomic (58 lines, single responsibility: inject CLAUDE.md section)
- `bulwark-scaffold/SKILL.md` already handles Justfile language detection and generation — absorbing this into init.sh would duplicate ~60 lines of detection logic
- `sync-hooks-for-dev.sh` is definitively dev-only (transforms CLAUDE_PLUGIN_ROOT → CLAUDE_PROJECT_DIR) — confirmed must stay separate

**CHALLENGE:** "Is a top-level `init.sh` orchestrator the right pattern, or should each init step be individually user-invocable?" The concern is that `init.sh` becomes a monolith that's hard to test in isolation.

**REFINE:** Split into two tiers:
- `init.sh` = thin orchestrator that prompts for each step and calls atomic scripts
- Atomic scripts remain independently runnable (`init-rules.sh`, `init-project-rules.sh`, `init-cleanup.sh` for AC17)
- Skills (`/bulwark-scaffold`, `/setup-lsp`) are invoked with clear user messaging, not scripted inline

This satisfies CS1 (Single Responsibility) at every layer. The orchestrator is explicitly ONLY an orchestrator — no business logic.

#### 2. CN Rule Conditional Inclusion

**PROPOSE:** Split rules template into two files:

```
lib/templates/
  rules-core.md     # Always installed: CS, T, V, ID, TR, SC, SR
  rules-cn.md       # LSP opt-in only: CN1, CN2
```

Init installs both as separate files in `.claude/rules/`:
```
.claude/rules/
  rules-core.md     # Always present
  rules-cn.md       # Present if LSP configured
```

**VALIDATE:** The `.claude/rules/` directory auto-loads all `.md` files present. This means:
- If user opts in to LSP → both files exist → both rule sets loaded
- If user opts out of LSP → only `rules-core.md` → CN rules never loaded
- No dynamic generation, no sed transforms, no config flags

**CHALLENGE:** "Does this create a rules-drift problem? If CN rules evolve, they live in one file that maps cleanly to user opt-in state." Actually this is BETTER than a monolithic file — the split makes the opt-in boundary explicit and auditable.

**REFINE:** Confirmed approach. Current `lib/templates/rules.md` should be renamed to `rules-core.md`. A new `rules-cn.md` is created with only CN1/CN2. The SME confirmed lib/templates/rules.md is missing CN1/CN2 anyway — fixing the gap and the architecture in one move.

**Edge case:** What about `init-rules.sh` that copies a single file? It needs to be updated to handle both files. Either extend `init-rules.sh` to accept a list of source files, or create a separate `init-rules-cn.sh`. I recommend extending `init-rules.sh` to accept an array: `init-rules.sh [core|cn|both]` — or make init.sh call `init-rules.sh` twice with different source args. Extending the script avoids proliferating tiny shell scripts.

#### 3. Justfile Installation (bulwark-scaffold delegation)

**PROPOSE:** Init delegates to `/bulwark-scaffold` as a RECOMMENDED step.

**VALIDATE:** `bulwark-scaffold/SKILL.md` Steps 2-7 handle: language detection (package.json → Node, pyproject.toml → Python, Cargo.toml → Rust), Justfile backup, template selection from `lib/templates/`, logs/ directory creation, and hook configuration. All of this is already implemented and validated.

**CHALLENGE:** "Does delegating to a skill from a shell script create an unresolved dependency?" Yes — `init.sh` cannot programmatically invoke `/bulwark-scaffold`. The init pipeline is a shell script; the skill is a Claude Code skill. These are two separate execution contexts.

**REFINE:** `init.sh` does NOT invoke bulwark-scaffold. Instead:
1. `init.sh` completes its mandatory steps (rules, CLAUDE.md injection)
2. At the end, prints: "RECOMMENDED: Run `/bulwark-scaffold` to set up Justfile and project tooling"
3. Users run the skill manually afterward

This is the correct architecture — init handles governance files (stateless copy operations), skills handle interactive scaffold (requires LLM judgment for language detection + template selection). These are fundamentally different operation types and should not be conflated.

#### 4. Cleanup Script (AC17)

**PROPOSE:** `scripts/hooks/cleanup-stale.sh` triggered via SessionStart hook, with age-based rotation using `find -mtime +10`.

**VALIDATE:** Current `hooks/hooks.json` has a SessionStart hook (`inject-protocol.sh`). Adding a second SessionStart hook would require adding another entry to the hooks array. This is structurally supported.

**CHALLENGE — Critical:** "How does the script distinguish new session vs resume vs compact?" This is the hardest problem in AC17. The hook fires on ALL SessionStart events including resume and post-compact. Running aggressive log deletion on resume would delete logs the user just created.

**Candidate solutions:**

| Approach | Mechanism | Risk |
|----------|-----------|------|
| Session marker file | Write `$PROJECT/.session-id` with UUID on first-run; skip cleanup if UUID matches | Reliable but adds state file |
| Environment variable | Check for `CLAUDE_SESSION_RESUMED` env var | Depends on env var existing (unverified) |
| Timestamp heuristic | Skip if `$PROJECT/.claude/hooks.log` was modified in last 60 seconds | Fragile |
| Accept double-fire | Run cleanup every time but only delete files >10 days old (not today's files) | Actually safe — 10-day threshold means new-session-only behavior by design |

**REFINE:** The "accept double-fire" approach is actually architecturally correct. If the age threshold is T-10 days, running cleanup on resume doesn't harm anything — files from today won't be deleted regardless. The complexity of session marker files adds state management overhead for zero real benefit.

The simpler architecture: `cleanup-stale.sh` runs on every SessionStart, deletes `logs/` and `tmp/` files older than 10 days, preserves `.gitkeep` files. The T-10 threshold IS the "new session only" guarantee — it's implicit in the math.

**Exception:** If the user wants to preserve logs from 5 days ago during a long resume session, this still won't delete them (5 < 10). The concern about "new session start only" is really about "don't delete recent work" — T-10 days achieves this without session detection complexity.

**Timeout consideration:** The existing SessionStart hook (inject-protocol.sh) uses timeout: 5000 (5 seconds). Cleanup of large log directories via `find` could take longer. Recommend timeout: 30 (30 seconds) for the cleanup hook.

#### 5. Distribution Architecture

**PROPOSE:** Marketplace primary, homebrew tap as milestone two, npm as milestone three (optional, low priority).

**VALIDATE:** From research synthesis:
- GitHub marketplace: `/plugin marketplace add owner/repo` — zero infrastructure, free hosting, Anthropic-governed discovery
- Homebrew tap: requires maintaining a separate tap repo + Formula file + version updates
- npm: adds package.json build pipeline, semantic versioning via npm, unrelated to Claude Code's plugin system

**CHALLENGE:** "Does marketplace-first lock users into a Claude Code-specific install path that limits adoption?" No — the plugin is Claude Code-native by definition. Non-Claude Code users have no use case. Homebrew/npm would add installation flexibility only for users who prefer CLI package managers, which is a valid but secondary concern.

**REFINE:** Distribution recommendation:

```
Tier 1 (MUST): GitHub marketplace (plugin marketplace add ashaykubal/the-bulwark)
Tier 2 (SHOULD): Homebrew tap (brew install ashaykubal/tap/the-bulwark)
Tier 3 (COULD): npm package (npm install -g @ashaykubal/the-bulwark) — lowest priority
```

Key constraint: For homebrew, the formula must know the plugin install location so it can wire the post-install hook that runs init.sh. This is non-trivial. Homebrew caveats section is the practical approach: print instructions after install.

### Design Patterns

**Pattern 1: Atomic Script Composition (CS1)**

Each init concern is one script, one responsibility:
```
init.sh (orchestrator — prompts and calls)
  ├── init-rules.sh [src-file] [target-dir]
  ├── init-project-rules.sh [target-dir]
  └── cleanup-stale.sh [target-dir] [days]
```

Scripts are independently executable. This is the existing pattern (init-rules.sh, init-project-rules.sh already follow it). Extend, don't break.

**Pattern 2: Skill Delegation for Interactive Steps**

Shell scripts handle deterministic file operations. Skills handle interactive, judgment-requiring steps. The boundary is firm:
- `init.sh` → file operations (rules.md copy, CLAUDE.md injection)
- `/bulwark-scaffold` → interactive scaffold (language detection + Justfile)
- `/setup-lsp` → interactive LSP (tech stack detection + binary install)

Init prints recommendations; users invoke skills manually.

**Pattern 3: Modular Rules via .claude/rules/ Directory**

The `.claude/rules/` directory auto-loads all `.md` files. Use this as the modularity primitive:
- `rules-core.md` = always present
- `rules-cn.md` = present if LSP configured

No dynamic file generation, no sed transforms, no frontmatter flags. Presence = enabled; absence = disabled.

**Pattern 4: Anti-Merge for Dev-Only Scripts**

`sync-hooks-for-dev.sh` must NOT be unified into init. It transforms variable namespaces for dogfooding — a development-only concern. Any refactor that touches this file during P7.1 risks breaking the dev feedback loop.

### Technical Trade-offs

| Decision | Chosen Approach | Alternative | Why Chosen |
|----------|----------------|-------------|------------|
| CN rule conditionality | Two-file split in .claude/rules/ | Dynamic rules.md generation | Simpler, no generated files, aligns with modular pattern |
| Justfile delegation | Print recommendation, user runs /bulwark-scaffold | Absorb detection logic into init.sh | Script ≠ skill execution context; avoids 60-line duplication |
| Cleanup new-session detection | T-10 day threshold (implicit) | Session marker file | Threshold IS the guarantee; marker file adds state management overhead |
| Init orchestration | Thin init.sh + atomic scripts | Monolithic init.sh | CS1 compliance; each script independently testable |
| Agent test-artifact exposure | Move to tests/fixtures/agents/ | Delete | Preserves test assets; removes from auto-discovery path |

### Integration Architecture

**Plugin install path (what `/plugin marketplace add` does):**
1. Clones repo to plugin location
2. Reads `.claude-plugin/plugin.json`
3. Auto-discovers `skills/`, `agents/` directories (directory-path format)
4. Registers hooks from `hooks/hooks.json`
5. Hooks fire using `${CLAUDE_PLUGIN_ROOT}` = plugin install location

**Post-install init path (what user runs after plugin install):**
1. First-run hook failure (#10997) means SessionStart won't fire automatically
2. User must restart session after install OR run init.sh manually
3. `init.sh` should print: "Restart your Claude Code session for hooks to take effect"

**Hook architecture (no changes to hooks.json except timeout correction):**
```
SessionStart:
  - inject-protocol.sh (governance injection, once:true)
  - cleanup-stale.sh (NEW: age-based log rotation)

PostToolUse (Write|Edit):
  - enforce-quality.sh → suggest-pipeline.sh

SubagentStart:
  - track-pipeline-start.sh

SubagentStop:
  - track-pipeline-stop.sh
```

**Timeout correction:** SME found timeout values are CORRECT (milliseconds per schema). No change needed. However, research synthesis said timeout: 60000 = 60 seconds. This warrants a verification step — check Claude Code's official schema definition for hook timeout units before changing anything.

**Agent auto-discovery boundary:**
```
.claude/agents/          ← NOT the plugin source (dogfood + dev)
agents/                  ← PLUGIN SOURCE (auto-discovered by plugin.json: "agents: agents/")
```

The `agents/` directory (10 agents) is what ships. The `.claude/agents/` directory (19 agents including test agents) is the dev copy. This is already correctly separated — plugin.json points to `agents/`, not `.claude/agents/`. The test agent concern raised by SME applies to `.claude/agents/` but NOT to the shipped plugin. Confirm this separation is maintained.

### Extensibility

**Rules modularity:** The `.claude/rules/` pattern supports future rule modules (e.g., `rules-security.md`, `rules-api.md`). Init only needs to know which files to copy — the directory handles loading. Future rule additions = new template file + init flag.

**Init step extensibility:** `init.sh` can add new recommended steps without changing atomic scripts. New integrations (e.g., future `/setup-editor` skill) follow the same delegation pattern.

**Distribution extensibility:** Adding homebrew/npm in a later milestone doesn't require changing the plugin itself — it's a packaging wrapper. Keep P7.1 scope to marketplace only.

**Plugin versioning:** `plugin.json` has `"version": "0.1.0"`. A semver discipline for plugins is important — marketplace users will pin versions. Establish versioning policy before launch: what constitutes a breaking change for plugin users?

## Recommendation

**Proceed.** The architecture is clear and all five design questions have answers derived from existing project patterns. No novel patterns are required.

---

## Post-Debate Update

### Peers reviewed:
- Product & Delivery Lead (02-product-delivery-lead.md)
- Critical Analyst (04-critical-analyst.md)

### Key findings from peer analyses:

**Critical Analyst — agents/ structural gap:**
CA claimed no root-level `agents/` directory exists. **Empirically verified this is INCORRECT.** `ls /mnt/c/projects/the-bulwark/` shows `agents/` present (modified Feb 24) with 10 agents. The SME also referenced it correctly in the Glob output. CA's highest-severity structural gap finding does not hold. The real question is ensuring the right agents are in root `agents/` (which plugin.json references) vs `.claude/agents/` (dogfood copy). This is an audit task, not a crisis.

**Critical Analyst — test-validator.md:**
CA correctly identified that `test-validator.md` exists in `.claude/agents/` and was missed by the SME's audit. Verified: `test-validator.md` IS present in `.claude/agents/`. If `.claude/agents/` is used as the plugin agents path, it must also be removed. Depends on agents/ path resolution.

**Critical Analyst — CN conditional inclusion simplification:**
CA proposes: include CN1/CN2 in base rules.md; they're preference-based and degrade gracefully. **I maintain my position.** The governance-reality gap (rules directing users to use a tool they haven't installed) is a real cost that the split-file approach eliminates for ~30 minutes of implementation effort. The modular `.claude/rules/` pattern was designed exactly for this use case. Sending targeted challenge to CA.

**Product & Delivery Lead — AC17 deferral:**
PDL recommends deferring AC17 citing session-distinction complexity and data-loss risk. **I disagree.** The T-10 day age threshold is the implicit session-distinction mechanism — files under 10 days old are never at risk regardless of whether the hook fires on resume vs new session. The complexity PDL describes (session marker files, detection logic) is unnecessary with the threshold approach. Sending targeted challenge to PDL.

**Agreement areas:**
- Delegate pattern (not absorb) for bulwark-scaffold and setup-lsp — both peers agree
- Marketplace primary distribution — both peers agree
- Test agent removal (code-analyzer.md, file-counter.md) — all peers agree

### Position updates after CA counter-challenges (round 2):

**UPDATED — CN conditional inclusion:**
CA challenged with: "What's the concrete governance failure mode if a user WITHOUT LSP gets CN1/CN2?" On re-reading, CN1 says "when LSP is available" — the conditionality is IN the rule text. CN2's hierarchy has Grep as an explicit fallback. A user without LSP who uses Grep is following the documented fallback, not violating the rule. No governance-reality gap exists. CA's re-run-after-LSP point is also valid: if a user installs LSP later, they'd need to re-run init to get cn-rules.md. Real UX friction I hadn't accounted for.

**FINAL POSITION**: Include CN1/CN2 in base rules.md unconditionally. Split-file approach was over-engineering. Rules self-degrade correctly by design.

**UPDATED — Timeout units:**
CA correctly challenged my "unresolved contradiction" framing. The research synthesis (Insight #12, HIGH confidence, cross-referenced against lazyptc-mcp and clear-framework) explicitly marks this RESOLVED — Question 6 in the synthesis is struck through as a closed question. The SME made a factual error. I re-opened a question the research phase had already closed.

**FINAL POSITION**: Timeout values are in seconds. Correct 60000→60, 30000→30, 5000→5 in hooks/hooks.json. Action item, not a design question.

**MAINTAINED — AC17 inclusion in P7.1:**
PDL's deferral concern rests on session-distinction complexity and data-loss risk. The T-10 day threshold makes session distinction irrelevant — files under 10 days old are never at risk regardless of hook firing on resume vs new session. No counter-challenge received from PDL.

**MAINTAINED — agents/ directory:**
CA's structural gap finding (agents/ doesn't exist) is empirically incorrect — verified `ls` shows root `agents/` present with 10 production agents. The correct framing: ensure root `agents/` is the canonical plugin source and `.claude/agents/` remains the dogfood copy.

### Revised implementation priority order:

1. Correct hooks.json timeout values: 60000→60, 30000→30, 5000→5 (settled — seconds)
2. Sync CN1/CN2 into `lib/templates/rules.md` directly (unconditional — no split file needed)
3. Update `init-rules.sh` target path from `$TARGET/Rules.md` to `$TARGET/.claude/rules/rules.md`
4. Create `scripts/init.sh` thin orchestrator (mandatory steps + post-init checklist for skills)
5. Create `scripts/hooks/cleanup-stale.sh` (AC17, add to SessionStart hooks — T-10 threshold)
6. Audit root `agents/` vs `.claude/agents/` — ensure test agents excluded from plugin source
7. Add marketplace metadata to plugin.json (repository, homepage, license, keywords)
