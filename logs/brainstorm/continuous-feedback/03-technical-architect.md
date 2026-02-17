---
role: technical-architect
topic: P5.3 continuous-feedback skill
recommendation: proceed
key_findings:
  - "4-stage pipeline maps cleanly to a 4-agent topology: 1 Collector (Sonnet), 2-3 Analyzers (Sonnet, parallel), 1 Proposer (Sonnet) — with the orchestrator handling Validate directly using existing tools"
  - "The Collector must output a normalized intermediate schema (source, category, content, skill_target) that decouples input parsing from analysis — this is the critical abstraction boundary that enables general-purpose operation"
  - "Per-skill specialization is implemented via swappable reference files (references/specialize-*.md), not code branching — matching the code-review skill's section-patterns.md and framework/*.md pattern"
---

# P5.3 Continuous-Feedback Skill -- Technical Architect

## Summary

The continuous-feedback skill fits naturally into the codebase's established multi-stage pipeline architecture, borrowing the directory layout from bulwark-brainstorm, the Pre-Flight Gate from test-audit, and the parallel sub-agent pattern from bulwark-research. The central architectural decision is the normalized intermediate format between Collect and Analyze: this schema is the abstraction boundary that makes the skill general-purpose while allowing per-skill specialization. The pipeline topology is 4 sequential-then-parallel agents with orchestrator-driven validation, totaling approximately 4 Sonnet sub-agent invocations per run.

## Detailed Analysis

### Architectural Approach

**Pipeline Topology: Sequential-Parallel-Sequential**

The pipeline follows a shape already proven in bulwark-brainstorm (SME sequential, 3 roles parallel, Critic sequential):

```fsharp
Collector(inputs)                          // Stage 1: Sonnet, sequential
|> [Analyzer(skill_type_1), Analyzer(skill_type_2), ...]  // Stage 2: Sonnet, parallel
|> Proposer(all_analyses)                  // Stage 3: Sonnet, sequential
|> Validate(proposal)                      // Stage 4: Orchestrator, no sub-agent
```

**Stage 0: Pre-Flight (Orchestrator)**
- Parse arguments: `<target-skill-or-path> [--sources <paths>] [--since <session-N>]`
- Resolve input sources: default to `sessions/*.md` + MEMORY.md; override with `--sources`
- Detect target skill type: read the target skill's SKILL.md frontmatter to determine specialization (code-review, test-audit, bug-magnet-data, or general)
- Load the matching specialization reference: `references/specialize-{skill-type}.md`
- Create output directory: `logs/continuous-feedback/{run-slug}/`
- Token budget check

**Stage 1: Collect (Sonnet sub-agent)**
- Input: raw session files, MEMORY.md, custom paths
- Task: parse structured sections (Learnings, Technical Decisions, Blockers, Defects, Framework Observations) and extract individual learning items
- Output: `logs/continuous-feedback/{run-slug}/01-collect.md` containing a normalized list of learning items

Each learning item follows this schema:
```yaml
- source: "session_45_20260208.md"
  section: "Learnings"
  category: "defect-pattern"  # defect-pattern | architecture-decision | framework-observation | workflow-improvement | tool-behavior
  content: "CRLF on WSL: New scripts on /mnt/c/ can get CRLF..."
  skill_relevance: ["code-review", "fix-bug"]  # which skills this learning might improve
```

This normalized format is the critical abstraction. The Collector deals with parsing heterogeneous inputs; the Analyzers deal with interpreting learnings against skill-specific context. Neither needs to understand the other's domain.

**Stage 2: Analyze (2-3 Sonnet sub-agents, parallel)**
- Input: normalized learning items from Stage 1 + the target skill's current state (SKILL.md, references/, templates/)
- Each Analyzer receives: (a) the full normalized learning list filtered to items with `skill_relevance` matching its specialization, (b) the specialization reference file, (c) the current skill files via autonomous codebase exploration
- Output: `logs/continuous-feedback/{run-slug}/02-analyze-{specialization}.md` containing categorized improvement targets with priority and rationale

The number of Analyzers is dynamic: one per detected specialization, capped at 3 to stay within token budget. If the user targets a single skill, one Analyzer runs. If continuous-feedback is invoked broadly (e.g., on the entire `.claude/skills/` directory), spawn up to 3 Analyzers for the top skill types by learning-item count.

**Stage 3: Act/Propose (Sonnet sub-agent)**
- Input: all Analyzer outputs + target skill's current files
- Task: synthesize analysis into a concrete change proposal document
- Output: `logs/continuous-feedback/{run-slug}/03-proposal.md`
- The proposal document uses a structured format: for each proposed change, specify the target file, the change type (add/modify/remove), a diff-like before/after, and the rationale traced back to specific learning items

**Stage 4: Validate (Orchestrator, no sub-agent)**
- Run `/anthropic-validator` on the proposed skill modifications (if the proposal targets skill assets)
- Run `just typecheck && just lint && just test` if the proposal includes code changes
- Append validation results to `logs/continuous-feedback/{run-slug}/04-validation.md`
- This stage is deterministic tool execution, not LLM judgment, so no sub-agent is needed

### Design Patterns

**Follow the bulwark-brainstorm directory layout.** The skill directory structure is:

```
.claude/skills/continuous-feedback/
  SKILL.md                              # Main skill definition
  references/
    specialize-code-review.md           # What to look for in code-review learnings
    specialize-test-audit.md            # AST gap analysis, detection patterns
    specialize-bug-magnet-data.md       # Edge case categories, external sources
    specialize-general.md               # Pattern extraction, incremental updates
    collect-instructions.md             # Parsing rules for session handoffs, MEMORY.md
  templates/
    collect-output.md                   # Normalized learning item schema
    analyze-output.md                   # Improvement target format
    proposal-output.md                  # Change proposal format with diff-like structure
    diagnostic-output.yaml              # Standard diagnostic schema
```

**Use the test-audit Pre-Flight Gate pattern.** The SKILL.md must include an explicit MUST/MUST NOT section at the top, preventing the orchestrator from performing analysis or proposal work itself. This is proven essential by DEF-P4-005 (agents ignore skill instructions without binding language).

**Use the bulwark-research parallel spawn pattern.** Stage 2 Analyzers spawn in a single message with multiple Task tool calls, matching the proven pattern from bulwark-research Stage 2 and bulwark-brainstorm Stage 3.

**Do NOT use the Critical Evaluation Gate.** This pattern (from bulwark-research and bulwark-brainstorm) is designed for interactive post-synthesis user Q&A. Continuous-feedback produces a proposal document for user review outside the session -- the user applies changes manually. Post-synthesis interaction is unnecessary and would consume token budget better spent on analysis depth.

### Technical Trade-offs

**Trade-off 1: Dynamic Analyzer count vs. fixed count.**
Prescription: Dynamic (1-3 based on detected skill types). A fixed 3-agent topology wastes tokens when targeting a single skill. The Collector's `skill_relevance` field drives this: after Stage 1 completes, the orchestrator counts unique skill types and spawns one Analyzer per type, capped at 3. This matches the test-audit mode-selection pattern (Scale vs. Deep based on file count).

**Trade-off 2: Collector as sub-agent vs. orchestrator-driven parsing.**
Prescription: Sub-agent. Session files are long (62 files, each 50-150 lines). Parsing all of them in the orchestrator's context would consume 25-40% of the token budget on raw text that the orchestrator then discards. A Sonnet Collector reads the files, extracts learning items, and returns a compact normalized list. The orchestrator only reads the compact output. This mirrors the bulwark-brainstorm SME pattern: offload context-heavy reading to a sub-agent.

**Trade-off 3: Full session history vs. windowed.**
Prescription: Windowed by default with `--since` flag. Reading all 62 sessions is wasteful when the last 5-10 contain the actionable learnings. Default to the last 10 sessions. Allow `--since session_50` to override. MEMORY.md is always read in full (it is the curated summary).

### Integration Architecture

**Input parsing.** The Collector sub-agent receives `references/collect-instructions.md` which documents the exact parsing rules for each input type:
- Session handoffs: extract `## Learnings` and `## Technical Decisions` sections using markdown heading boundaries. The YAML header provides session number and date for recency weighting.
- MEMORY.md: extract `## Defects & Lessons Learned`, `## Architecture Decisions`, and `## Framework Observations` sections.
- Custom paths: read file contents and extract any structured learning content (the Collector uses its judgment here, guided by the reference file).

This parsing is LLM-driven, not regex-driven. The session handoff template (defined in `/mnt/c/projects/the-bulwark/.claude/skills/session-handoff/SKILL.md`) is consistent but not machine-parseable by regex due to free-text content within structured sections. A Sonnet agent handles the ambiguity.

**Output format.** The proposal document (`03-proposal.md`) uses a structured format that a human can review and apply:
```markdown
## Proposed Change 1: Add WSL CRLF detection to code-review security patterns

**Target**: `.claude/skills/code-review/references/security-patterns.md`
**Change type**: Add section
**Source learnings**: session_45 (CRLF on WSL), session_58 (cascading sed collision)
**Priority**: Medium

### Proposed addition:
[content to add]

### Rationale:
[why this improves the skill, traced to specific learning items]
```

**Validation hooks.** The orchestrator invokes `/anthropic-validator` on target files listed in the proposal. This uses the existing Main Context Orchestration pattern from `/mnt/c/projects/the-bulwark/.claude/skills/anthropic-validator/SKILL.md` -- spawn claude-code-guide, then spawn bulwark-standards-reviewer. The continuous-feedback orchestrator does NOT re-implement validation; it delegates to the existing skill.

**SA2 compliance.** All sub-agent outputs go to `logs/continuous-feedback/{run-slug}/`. The orchestrator reads these files, not raw agent output. This matches the SA2 rule exactly.

### Extensibility

**Adding new skill specializations.** Drop a new `references/specialize-{type}.md` file into the skill directory. The orchestrator detects specialization by matching the target skill's name or frontmatter against available specialization reference files. No SKILL.md modification needed for new specializations -- the file's presence is sufficient.

**Generalizing beyond Bulwark.** The skill assumes two things about the target project: (1) it has `.claude/skills/` with SKILL.md files, and (2) it has `sessions/` with handoff files or some equivalent learning source. Both are Claude Code conventions. For projects without session handoffs, the `--sources` flag allows specifying alternative learning inputs (e.g., a changelog, a retrospective document, a DECISIONS.md file). The Collector's LLM-driven parsing handles format variation.

**Growing the input source vocabulary.** New source types (e.g., GitHub issue comments, PR review threads, CI failure logs) require only updating `references/collect-instructions.md` with parsing guidance for the new format. No pipeline changes needed -- the Collector is an LLM agent that adapts to new parsing instructions.

## Recommendation

**Proceed.** The architecture maps directly onto proven patterns already in the codebase. The 4-agent topology (Collector, 1-3 Analyzers, Proposer) with orchestrator-driven validation is the minimum viable pipeline that addresses both user pain points: the Analyzers solve "identifying what to improve" and the Proposer solves "proposing concrete changes." The normalized intermediate format between Collect and Analyze is the key architectural decision that enables general-purpose operation without sacrificing per-skill specialization. Implementation estimate: 1 session for SKILL.md + references + templates, matching the P5.14 precedent where bulwark-research and bulwark-brainstorm were each implemented in approximately 1 session.
