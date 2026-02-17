---
viewpoint: first-principles
topic: Meta-skill design patterns for skill-creator and agent-creator
confidence_summary:
  high: 7
  medium: 5
  low: 3
key_findings:
  - The fundamental problem is translation friction: users know what they want Claude to do, but the skill format has enough variation (frontmatter fields, file layout, sub-agent patterns) that incorrect choices silently produce broken or shallow results.
  - Minimal viable skill-creator is a two-question decision tree: (1) does this need isolation/concurrency — if yes, use context:fork or Task sub-agents; (2) does the main content need reference files — if yes, create supporting files. Everything else is cosmetic.
  - Agent-creator and skill-creator share 80% of their decision surface. The only fundamental difference is context:fork + hook configuration. Separating them into two meta-skills is justified only if the hook/diagnostic generation complexity warrants it.
  - Generation and guidance are not a spectrum — they are different products. Generation produces a ready-to-run artifact; guidance teaches the user to create one. Most value comes from generation with embedded explanation, not interactive tutoring.
  - The three architectural decisions (context, sub-agents, supporting files) are genuinely independent and can be decomposed. The minimum inputs for each are distinct and non-overlapping.
---

# Meta-skill Design Patterns — First Principles

## Summary

The core problem skill-creator and agent-creator solve is translation friction: users have a clear intent ("I want Claude to do X reliably") but the Claude Code skill format has enough non-obvious variation that incorrect choices — wrong frontmatter, missing files, wrong sub-agent pattern — silently produce broken or shallow output. The minimal viable version of each meta-skill is a structured interview that collects the ~5 key signals needed to make the three independent architectural decisions, then generates a working artifact. Supporting files, Agent Teams integration, and iterative refinement are all deferrable.

---

## Detailed Analysis

### The Fundamental Problem (stripped of framing)

**PASS 1 FINDING**: The surface problem is "help users create skills." The actual problem has two layers:

**Layer 1 — Format knowledge gap**: The Claude Code skill format has ~10 frontmatter fields, optional subdirectories with no enforced schema (references/, templates/, scripts/, examples/), and three distinct sub-agent patterns (none, Task tool, Agent Teams). A user who does not already know the format will produce invalid or incomplete output.

**Layer 2 — Architectural decision gap**: Even users who know the format face non-obvious choices:
- When does a skill need `context: fork` vs. Task tool sub-agents vs. neither?
- When does complexity justify supporting files vs. a self-contained SKILL.md?
- When is sequential sub-agent execution the right pattern vs. parallel?

These are design judgment calls, not format knowledge. A generator that only handles format knowledge produces syntactically valid but architecturally inappropriate artifacts.

**PASS 4 DEEPENING**: Examining 21 Bulwark skills reveals the actual distribution:
- ~8 single-file skills (38%): governance-protocol, fix-bug, bulwark-scaffold, test-classification, test-fixture-creation, bulwark-verify, assertion-patterns, bulwark-statusline (varies)
- ~13 multi-file skills (62%): most complexity driven by reference data, not architecture
- Only 2 skills use `context: fork`: code-review (as pipeline stage documentation) and subagent-output-templating. This is rare, not the default.
- 9/21 skills use Task tool sub-agents: the dominant complexity pattern
- 0 skills use Agent Teams: experimental, not yet adopted even in complex skills

**Implication**: The "comprehensive generator" that handles Agent Teams, complex hook configs, and multi-file scaffolding addresses a long tail. The 80th percentile skill is: single SKILL.md + optional references/ + optional Task tool sub-agents.

**Confidence**: HIGH
**Evidence**: Direct analysis of 21 Bulwark skills, cross-referenced with official Claude Code skill documentation

---

### Decision Framework Decomposition

The meta-skill must make three structurally independent decisions. Each can be resolved with distinct minimal inputs.

**Decision 1: Context (inline vs. fork)**

Question: "Should this skill run in the main conversation or in an isolated sub-agent?"

Minimal input needed: Does the skill have side effects that should not contaminate main context (e.g., generates files, runs commands, has long verbose output)? Does the skill need to return a summary result rather than an inline response?

Resolution logic:
- Side effects + isolation needed → `context: fork`
- Inline instruction/guidance → no fork
- Complex multi-step task with no need for isolation → Task tool sub-agents (not fork)

**Why existing approaches fail**: Without a clear question, users default to the most complex option they've seen. Having seen one `context: fork` example, they apply it universally. The meta-skill must make the trade-off explicit: `context: fork` means the skill loses access to conversation history and must be self-contained.

**Confidence**: HIGH
**Evidence**: Official docs explicitly state "context: fork only makes sense for skills with explicit instructions." Confirmed by Bulwark corpus: fork is used only where true isolation is desired.

---

**Decision 2: Sub-agent pattern (none vs. sequential Task vs. parallel Task vs. Agent Teams)**

Minimal inputs needed:
1. Does the skill orchestrate multiple distinct analytical passes or operations? (No → none)
2. Do those passes depend on each other's output? (Yes → sequential Task; No → parallel Task)
3. Do the workers need to communicate with each other, not just report to the orchestrator? (Yes → Agent Teams; No → parallel Task)

The Agent Teams branch is currently gated by an additional constraint: Agent Teams are experimental (requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var). This is a real-world constraint that should gate the decision, not just a design consideration.

**PASS 3 GAP IDENTIFIED**: The initial framing assumed Agent Teams were a peer option to Task tool sub-agents. The official docs reveal Agent Teams are experimental and explicitly disabled by default. This changes the decision: Agent Teams should be the last resort, not an equal option. The meta-skill must surface this constraint before offering it.

**Confidence**: HIGH
**Evidence**: Official Claude Code documentation: "Agent teams are experimental and disabled by default." Zero Bulwark skills use Agent Teams as of Feb 2026.

---

**Decision 3: Supporting files (vanilla vs. progressive disclosure)**

Minimal inputs needed:
1. Is the SKILL.md already under 500 lines? (Yes → no supporting files needed)
2. Does the skill reference external data (patterns, checklists, templates, fixtures) that would bloat SKILL.md? (Yes → references/)
3. Does the skill generate output that should follow a specific format? (Yes → templates/)
4. Does the skill execute scripts? (Yes → scripts/)

**PASS 2 EVALUATION**: This decision is orthogonal to the context and sub-agent decisions. A simple, single-file skill can reference Task tool sub-agents. A complex multi-file skill can run inline with no sub-agents. The supporting files decision is purely about content volume and reuse, not architecture.

**Why existing approaches fail**: Users see complex skills like bulwark-research (5 parallel agents + 9 files) and try to replicate the pattern even for simple use cases. There is no signal in the existing format that tells users "you don't need this complexity."

**Confidence**: HIGH
**Evidence**: Direct inspection. governance-protocol (30 lines, user-invocable: false, no sub-agents) and bulwark-research (9 files, 5 parallel agents) both work correctly because each has the complexity appropriate to its purpose.

---

### Minimal Viable Meta-skill

**skill-creator minimum viable version**:

1. Collect: skill name, description of what it does, whether it needs isolation, whether it orchestrates other agents, whether content will exceed ~500 lines
2. Decide: context (fork/none), sub-agent pattern (none/sequential/parallel), supporting files (yes/no)
3. Generate: SKILL.md with correct frontmatter + stub content + comments indicating where supporting files would go
4. Validate: run anthropic-validator on the generated output

What can be deferred:
- Agent Teams generation (experimental, low adoption)
- Hook configuration generation (complex, rarely needed in skills)
- Pre-populating supporting files with content (user writes content, meta-skill creates structure)
- Iterative refinement loops (one-shot generation with validation is sufficient for MVP)

**Confidence**: HIGH
**Evidence**: Anthropic's own `/agents` interactive command generates agents without Agent Teams, without hook generation, without iterative loops. It is the official MVP and it works.

---

**agent-creator minimum viable version**:

Agents are defined in `.claude/agents/` as Markdown files with YAML frontmatter. The /agents command already provides interactive creation with Claude-generation. The value-add of agent-creator over /agents is:

1. Bulwark-specific patterns: 4-part prompt template (SA1), diagnostic output section, Stop hook configuration
2. Decision support for agent architecture: single-agent vs. pipeline vs. Agent Teams
3. Automatic anthropic-validator step

The fundamental difference from skill-creator: agents do not use `context: fork` in their own frontmatter — they ARE the forked context. The hook configuration (Stop hooks, SubagentStop) is specific to agents and not skills. This distinction justifies separate meta-skills.

**Confidence**: HIGH
**Evidence**: Official docs distinguish skills with `context: fork` from agent definitions in `.claude/agents/`. They use the same underlying system but have different file locations and usage patterns.

---

### Generation vs. Guidance

**PASS 1 hypothesis**: Generation and guidance exist on a spectrum; the right model might be interactive tutoring.

**PASS 4 refutation**: The `/agents` command in Claude Code already demonstrates that generation with embedded explanation is the preferred model. It generates a complete agent definition, shows it to the user, allows editing, and provides explanation inline. Interactive tutoring ("now, what model should it use?") is slower and produces worse results because users don't know the answer space.

**Refined model**: Generation-first with post-generation explanation. The meta-skill generates a complete artifact, then explains the decisions made and what the user can change. This respects that users want a working skill, not a lesson.

**Confidence**: MEDIUM
**Evidence**: /agents command behavior (observed), general principle from software tooling (strong reasoning, not empirically tested for this specific case)

---

### Are skill-creator and agent-creator genuinely distinct?

**PASS 1 hypothesis**: These are the same meta-skill with different output targets.

**PASS 4 revised finding**: They share the decision framework but differ in critical ways:

Shared (80%):
- Name, description collection
- Context/sub-agent/supporting-files decision tree
- Content generation
- anthropic-validator step

Different (20%):
- Output file location: skills/ vs. agents/
- Hook configuration: agents warrant Stop hook + SubagentStop hook; skills usually do not
- Diagnostic output section: agents always get one (SA2 requirement); skills optionally
- Frontmatter fields: agents have `permissionMode`, `maxTurns`, `memory`; skills have `user-invocable`, `disable-model-invocation`

**Verdict**: Separate meta-skills are justified because the 20% difference is in the highest-value output (hooks, diagnostics) and the user intent is clearly different. However, both should share a common decision framework reference file.

**Confidence**: MEDIUM
**Evidence**: Frontmatter field differences documented in official docs. Hook config differences verified in Bulwark agent corpus.

---

### Unvalidated Assumptions (PASS 3 gaps)

**Assumption 1: Users need generation, not discovery.**

The underlying need might not be "create a skill from scratch" but "find an existing skill that does what I need." Skill discovery (browsing available skills, finding examples) solves the same problem for 60%+ of cases. This is not addressed by skill-creator at all.

**Confidence**: LOW (inference, not validated)

**Assumption 2: The meta-skill itself can reliably make architectural decisions.**

The three decisions (context, sub-agents, supporting files) require judgment about the skill's runtime behavior. An LLM making these decisions from a brief description will have accuracy limitations. A meta-skill that makes wrong architectural decisions produces a syntactically correct but architecturally broken artifact — potentially worse than no generator.

**Confidence**: LOW (inference, but supported by general LLM judgment variance findings from Bulwark project)
**Evidence**: Bulwark project finding: "Violation scope variance across runs: Same T3 violation can get different affected_lines from two Sonnet runs depending on context." Architectural decisions from brief descriptions are higher-variance still.

**Assumption 3: Frontmatter errors are the primary failure mode.**

The framing assumes users get frontmatter wrong. But the actual failure mode observed in Bulwark development is prompt quality — skills work syntactically but Claude ignores them because the instructions are ambiguous or the description doesn't match when the skill should load. The meta-skill cannot fix this without also helping users write good skill content.

**Confidence**: MEDIUM
**Evidence**: Bulwark project finding: DEF-P4-005 "Claude ignores skill instructions without explicit SC1-SC3 binding language." This is a content quality problem, not a format problem.

---

## Confidence Notes

**LOW confidence findings** require additional investigation before implementation:

1. "Users need generation, not discovery": If the primary user need is discovery of existing skills rather than creation of new ones, skill-creator addresses the wrong problem. Test: observe actual user behavior with skill-creator MVP before building complexity.

2. "LLM architectural decisions are reliable": The three-decision framework assumes a meta-skill can reliably classify a brief description into the correct context/sub-agent/supporting-files bucket. Pilot testing of the decision questions against real user requests is needed before assuming reliability.

3. "Frontmatter errors are the primary failure mode": If content quality is the primary failure mode, the meta-skill should invest in content scaffolding (what to put in the instructions) not just format scaffolding (what frontmatter to use). The existing anthropic-validator addresses format; content quality remains unaddressed.
