---
topic: Meta-skill design patterns for skill-creator and agent-creator
phase: research
agents_synthesized: 5
confidence_distribution:
  high: 12
  medium: 8
  low: 4
---

# Meta-skill Design Patterns — Research Synthesis

## Key Findings (Convergent)

Findings where multiple viewpoints agree — these are high confidence.

| # | Finding | Supporting Viewpoints | Confidence |
|---|---------|----------------------|------------|
| 1 | **Generate-and-customize, not generate-final**: Generated output is a scaffold requiring user customization, not a finished product. Rails, Yeoman, CRA, and practitioner data (30-50% rework on official skill-creator output) all converge on this. The meta-skill's contract must be explicit: "this is a starting point." | Prior Art, Practitioner, First Principles | HIGH |
| 2 | **Pre-generation interview is the core mechanism**: The interview determines output quality more than generation logic. Anthropic's 6-step starts with "Understanding with Concrete Examples." JHipster's wizard, AI-era tools (Copilot Workspace, Cursor), and First Principles analysis all confirm: the interview IS the classification. | Direct Investigation, Prior Art, First Principles | HIGH |
| 3 | **Three independent architectural decisions**: The meta-skill must make three orthogonal choices: (a) context — fork vs. inline, (b) sub-agent pattern — none/sequential/parallel/Agent Teams, (c) supporting files — vanilla vs. progressive disclosure. Each has distinct minimal inputs and can be resolved independently. | Direct Investigation, First Principles | HIGH |
| 4 | **Agent body = system prompt; skill body = task instructions**: Agent files (`.claude/agents/`) produce the system prompt (WHO IT IS). Skills with `context: fork` produce the task (WHAT TO DO). Agent-creator must generate in the system-prompt register. This is a fundamental structural difference confirmed by official docs. | Direct Investigation | HIGH |
| 5 | **YAML frontmatter description is highest-stakes**: Must be single-line (multi-line silently breaks discovery — GitHub #9817/#4700). Must use "when to use" framing. ~50% baseline activation rate; description quality is the primary lever. | Practitioner | HIGH |
| 6 | **Agent Teams is experimental, last-resort**: Gated by env var. Zero Bulwark skills use it. The deciding criterion for Agent Teams is inter-agent communication need, not just parallelism. Should be offered as an option but not as a default recommendation. | Direct Investigation, First Principles, Contrarian | HIGH |
| 7 | **No existing meta-skill uses iterative sub-agent generation**: All external references (Anthropic skill-creator, FrancyJGLisboa, Skill Seekers) use single-pass generation. Bulwark's proposed pattern (generate + validate + retry) is novel. | Direct Investigation | HIGH |
| 8 | **Transparency of generated output is non-negotiable**: The 4GL/CASE failure pattern (Oracle Designer, CRA) shows that hiding complexity fails. Generated skills are Markdown = already transparent. But the meta-skill must ensure generated output is fully legible and self-explanatory to a developer reading it cold. | Prior Art, Contrarian | HIGH |
| 9 | **Skill-creator and agent-creator share 80% of logic**: Both collect requirements, classify complexity, generate output, validate. The 20% difference (hooks, diagnostics, frontmatter fields, file location, system-prompt vs. task-instruction register) is in the highest-value output and justifies separate meta-skills. Both should share a common decision framework reference. | First Principles | HIGH |
| 10 | **context:fork is rare in practice**: Only 2/21 Bulwark skills use fork. 9/21 use Task tool sub-agents. 0 use Agent Teams. The typical generated skill is simpler than complex examples suggest. | First Principles | HIGH |
| 11 | **Degrees of freedom applied per-component, not per-skill**: A complex skill like test-audit has low-freedom components (AST scripts) AND high-freedom components (synthesis prose). The Anthropic skill-creator's degrees-of-freedom framework (High/Medium/Low) is the most evolved classification found. | Direct Investigation, Prior Art | HIGH |
| 12 | **Specialize per skill type, not one general template**: The DSL narrowness lesson (narrow-domain DSLs succeed; general ones fail) maps to skill-creator generating different structural templates per skill type (AST-script, pipeline, research, governance) rather than one universal template. | Prior Art | MEDIUM |

## Tensions and Trade-offs

### Tension 1: Bounded MVP vs. Comprehensive Generator

- **View A** (First Principles, Contrarian): Minimal viable version is a ~5-question structured interview + single-pass generation + anthropic-validator. Agent Teams, hook generation, and iterative refinement are deferrable. Bounded scope avoids decision tree fragility and the second-system trap.
- **View B** (Direct Investigation, tasks.yaml acceptance criteria): Full meta-skill framework that decides architecture (scripts, sequential sub-agents, parallel sub-agents, Agent Teams). Multi-stage workflow: Pre-Flight → Generate (sub-agent) → Validate → Refine.
- **Implication**: The acceptance criteria require the comprehensive framework, but implementation can be layered — start with the interview + single-pass + validate core, then add Agent Teams and iterative refinement as extensions. The interview quality drives output quality regardless of which scope we choose.

### Tension 2: Decision Tree Automation Reliability

- **View A** (Contrarian): Decision tree cannot be automated reliably. LLM classifying a brief description into the correct context/sub-agent/supporting-files bucket will make errors. Wrong architecture decisions produce syntactically correct but functionally broken output.
- **View B** (Direct Investigation, Prior Art): The communication-dependency matrix works for sub-agent selection. AI-era tools resolve classification via conversation, not inference. The three decisions have clear minimal inputs.
- **Implication**: The meta-skill should use conversational elicitation (asking the user "does this need isolation?", "do workers need to communicate?") rather than inferring from the description alone. This aligns with the "interview IS the classification" finding.

### Tension 3: Quality Ceiling and Activation Reliability

- **View A** (Contrarian): Generated skills can't match hand-crafted for behavioral precision. Platform has ~50% baseline activation rate. "False confidence" from having a generated skill is worse than no skill.
- **View B** (Practitioner, Prior Art): Generated output is explicitly a scaffold. Users customize post-generation. The meta-skill adds structural correctness (frontmatter, file layout) and validation (anthropic-validator), which are the cheapest-to-automate, hardest-to-get-wrong parts.
- **Implication**: Make the scaffold contract explicit. Include description-quality guidance and activation-tuning instructions in generated output. Don't claim the generated skill is production-ready.

### Tension 4: Maintenance Coupling and Staleness

- **View A** (Contrarian): CRA/Yeoman decay pattern. Improvements don't flow back to already-generated skills. Multi-tier staleness across skills generated at different times.
- **View B** (Prior Art): Bulwark has a structural advantage — meta-skills live in the same repo as the skills they generate. Templates can reference actual conventions rather than duplicating them.
- **Implication**: Design the meta-skills to reference live skill examples from the codebase (or from a configurable examples directory) rather than hardcoding patterns. This makes the generator self-updating as the repo evolves.

## Unique Insights

Findings from a single viewpoint that add important nuance.

| # | Insight | Source Viewpoint | Confidence |
|---|---------|-----------------|------------|
| 1 | Tool permissions for agents has no clean solution — feature request #10093 closed NOT_PLANNED (Jan 2026). Generated agents must include manual permission setup instructions. | Practitioner | HIGH |
| 2 | Agent-creator is genuinely novel — 30 years of MAS research validates multi-agent patterns but no precedent exists for generating agent orchestration as prose documents. | Prior Art | HIGH |
| 3 | The FrancyJGLisboa agent-skill-creator uses a 6-phase discovery workflow with per-phase reference docs. Closer to Bulwark's pattern than the official Anthropic skill-creator. | Direct Investigation | MEDIUM |
| 4 | Sionic AI's `/retrospective` command auto-commits skill updates after each experiment. Living-document maintenance is high-value but only works with CI/CD discipline. | Practitioner | MEDIUM |
| 5 | LLM non-determinism means same requirements produce structurally different skills across runs. Quality is partly a function of random seed. Validate-and-retry loop partially mitigates this. | Contrarian | MEDIUM |
| 6 | The `/agents` built-in command already provides interactive agent creation with Claude-generation. Agent-creator's value-add is Bulwark-specific patterns (SA1, diagnostics, Stop hooks) and architecture decision support. | First Principles | HIGH |
| 7 | Stop hook in agent frontmatter is automatically converted to SubagentStop at runtime. This is the canonical mechanism for agent-creator to generate diagnostic output capability. | Direct Investigation | HIGH |
| 8 | context:fork skills with only guidelines and no actionable task become no-ops. The meta-skill must enforce that forked output includes explicit task instructions. | Practitioner, Direct Investigation | HIGH |

## Confidence Map

| Finding | Supporting Viewpoints | Confidence |
|---------|----------------------|------------|
| Generate-and-customize contract | Prior Art, Practitioner, First Principles | HIGH |
| Interview-driven classification | Direct Investigation, Prior Art, First Principles | HIGH |
| Three independent architectural decisions | Direct Investigation, First Principles | HIGH |
| System-prompt vs. task-instruction register | Direct Investigation | HIGH |
| Description field criticality | Practitioner | HIGH |
| Agent Teams as last resort | Direct Investigation, First Principles, Contrarian | HIGH |
| No iterative generation in prior art | Direct Investigation | HIGH |
| Transparency of generated output | Prior Art, Contrarian | HIGH |
| 80/20 shared logic split | First Principles | HIGH |
| Decision tree via conversation not inference | Prior Art, Contrarian, Direct Investigation | MEDIUM |
| Quality ceiling / scaffold contract | Contrarian, Practitioner | MEDIUM |
| Skill-type specialization | Prior Art | MEDIUM |
| Non-determinism as quality variance | Contrarian | MEDIUM |
| Second system trap risk | Contrarian | LOW |
| Users need discovery not generation | First Principles | LOW |

## Open Questions

1. **Should the meta-skills share a common decision framework reference file?** First Principles recommends this (80% overlap). How much of the interview and classification logic should be in a shared `references/decision-framework.md` vs. duplicated in each SKILL.md?

2. **How many interview questions is optimal?** First Principles says ~5. The Anthropic skill-creator asks for concrete examples first, then classifies. JHipster uses a comprehensive wizard. What's the right balance between thoroughness and friction for Claude Code users?

3. **Should generated skills include inline explanations of architectural decisions?** Prior Art (4GL/Rails) says transparency is essential. But inline comments add length and may push skills over context budget. What's the format — inline comments, a separate DECISIONS.md, or a post-generation summary to the user?

4. **How to handle the Anthropic skill-creator overlap?** The official skill-creator exists in `example-skills:skill-creator`. Bulwark's skill-creator extends it with SA1-SA6 compliance, multi-agent pattern generation, and anthropic-validator integration. Should it explicitly reference the Anthropic skill-creator as a dependency/peer, or be fully standalone?

5. **What skill types should the meta-skill specialize for?** Prior Art suggests per-type templates. Candidates from the Bulwark corpus: (a) simple instruction skill, (b) reference-heavy skill, (c) pipeline/multi-stage skill, (d) AST/script-driven skill, (e) research/brainstorm skill. How many type templates are needed in v1?

## Implications for Next Steps

### For P5.4 (skill-creator) Implementation

1. **Core workflow**: Structured interview (5-7 questions using AskUserQuestion) → Classify (three independent decisions) → Generate (Sonnet sub-agent with skill-type template + examples from codebase) → Validate (anthropic-validator) → Present scaffold to user with decisions explained
2. **Interview questions should map to the three decisions**: context isolation need, sub-agent communication need, content volume/domain-specificity
3. **Output contract**: Explicitly state "this is a scaffold — customize before production use"
4. **Description generation**: Single-line, "when to use" framing, trigger-specific
5. **Skill-type templates**: Generate different structures per detected skill type (simple, reference-heavy, pipeline, script-driven)
6. **Agent Teams**: Include as an option in classification but with explicit experimental warning and env var gating

### For P5.5 (agent-creator) Implementation

1. **System-prompt register**: Generated agent body must read as identity/mission (WHO), not task instructions (WHAT)
2. **Stop hook generation**: Include `Stop` hook in frontmatter for diagnostic output (auto-converts to SubagentStop)
3. **Permission documentation**: Generated agents must include a section documenting what permissions the user needs to configure manually
4. **SA1 compliance**: Include `subagent-prompting` in `skills:` frontmatter and reference GOAL/CONSTRAINTS/CONTEXT/OUTPUT in agent protocol
5. **context:fork is implicit**: Agents in `.claude/agents/` always fork. The agent-creator doesn't need to ask about forking — it's inherent in the agent format

### Shared Between Both

- Common decision framework reference file (interview questions, classification logic)
- anthropic-validator as validation gate
- Generate-and-customize contract in output
- Single-line description enforcement
- Codebase-referenced examples (not hardcoded patterns)

## Post-Synthesis Decisions (User Input)

### Decision 1: Open Questions Priority
**Selected**: Interview depth and Skill-type templates as the two questions requiring resolution before brainstorm/implementation. Other questions (shared reference file, inline explanations, Anthropic overlap) deferred to brainstorm phase.

### Decision 2: Content Scope
**Selected**: Structure + content guidance. The meta-skills will include content scaffolding: good/bad instruction examples, description writing patterns, common pitfalls. This addresses the Contrarian's valid point that structure automation alone is low-value.

### Decision 3: Relationship to Anthropic's skill-creator
**Selected**: Adopt and adapt. Fork Anthropic's skill-creator as the foundation, modify for Bulwark conventions (SA1-SA6, multi-agent patterns, anthropic-validator integration, content guidance), maintain as a derivative.

### Decision 4: Interview Depth
**Selected**: Adaptive depth. Start with 5 core questions covering the three architectural decisions (context, sub-agents, files) plus name/description/triggers. If answers suggest complexity (sub-agents, multiple references, pipeline patterns), ask 3-5 follow-up questions. Simple skills get 5 questions; complex skills get 10-12. This aligns with the research finding that "the interview IS the classification."

### Decision 5: Skill-Type Templates
**Selected**: 5 templates (full taxonomy):
1. **Simple** — Vanilla SKILL.md only
2. **Reference-heavy** — SKILL.md + references/
3. **Pipeline** — SKILL.md + references/ + templates/ + multi-stage orchestration
4. **Script-driven** — SKILL.md + scripts/ (deterministic execution)
5. **Research/Brainstorm** — SKILL.md + references/ + templates/ + parallel/sequential multi-agent

This covers the full Bulwark corpus and aligns with the Prior Art finding that narrow-domain templates succeed over general-purpose ones.

## Incomplete Coverage

No agent failures. All 5 viewpoints completed successfully with 0 retries.
