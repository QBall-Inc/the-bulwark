# Authoring Log: plan-creation-qa-critic

**Agent file**: `.claude/agents/plan-creation-qa-critic.md`
**Authored**: 2026-02-23
**Author**: Primary model (orchestrator mode, direct implementation)
**Template reference**: `skills/create-skill/references/agent-template.md`
**Convention reference**: `skills/create-skill/references/agent-conventions.md`

---

## Design Decisions

### 1. Identity Framing: Adversarial, Not Procedural

The agent opens with two identity paragraphs instead of one. The first establishes role and expertise. The second makes the adversarial mandate explicit: "You are explicitly adversarial. You do not validate what prior agents said — you challenge it."

**Rationale**: Without this framing, LLM agents default to synthesis and validation behavior. The QA/Critic role is different — it must actively seek gaps the other agents missed. Stating this identity constraint in the system prompt locks in the adversarial disposition before any task instructions apply. This follows the behavioral pattern established in `plan-creation-po.md` (two-paragraph opens when the role has a non-obvious behavioral mode).

### 2. Pre-Flight Gate: "Novel Gap" Obligation

The Pre-Flight Gate includes a REQUIRED obligation specifically about finding novel gaps: "Seek at least one substantive gap that was NOT raised by any prior agent — this is the primary pipeline success criterion for your role."

**Rationale**: Without explicit binding language, agents naturally optimize toward restating prior findings (safe) rather than finding new ones (valuable). The Pre-Flight Gate pattern (from DEF-P4-005) ensures this constraint is binding, not advisory. The phrase "primary pipeline success criterion" links the obligation to the task brief's success criterion verbatim.

### 3. Protocol: "What did ALL THREE agents collectively overlook?" framing

Step 2 (Read All Prior Outputs) explicitly instructs the agent to look for "assumptions that run through ALL THREE outputs unchallenged." Step 4 frames gap identification as "cross-cutting gaps — issues that span PO + Architect + Eng Lead and thus fall through the cracks between roles."

**Rationale**: The most valuable QA/Critic findings are cross-cutting — they emerge from the seams between roles, not within any single role's scope. Without this framing, agents naturally critique each prior output in isolation, which duplicates intra-role concerns already addressed within each stage.

### 4. Codebase Verification: Optional and Targeted

The protocol includes an optional Step 3 for codebase verification, explicitly scoped to "targeted verification of specific claims made by prior agents" rather than broad exploration.

**Rationale**: Prior agents (PO, Architect) already explored the codebase. Repeating broad exploration wastes the agent's context window and produces redundant findings. The value is in targeted contradiction-finding: "The Architect said X exists — does it?" This is cheaper and more valuable than re-exploring. The DO NOT section reinforces this: "Re-derive requirements or re-do architectural analysis."

### 5. Kill Criteria as a Required Output Section

Kill criteria are a named, mandatory output section with a minimum of 5 conditions and measurability requirements.

**Rationale**: Kill criteria are frequently omitted from implementation plans because they require committing to failure conditions upfront. Making them a required output section (with minimum count and verifiability constraint) ensures the plan addresses project abandonment conditions explicitly. This is one of the QA/Critic's unique contributions per the task brief — PO, Architect, and Eng Lead do not produce kill criteria.

### 6. Verdict: Structured with Conditions

The verdict section has three branches (APPROVE / MODIFY / REJECT) with different output formats. MODIFY requires a checklist of required changes. REJECT requires describing the structural problem.

**Rationale**: A verdict without conditions is an observation, not actionable guidance. The MODIFY checklist ensures the orchestrator (and user) know exactly what must change before the plan proceeds. This pattern mirrors the `bulwark-standards-reviewer.md` pattern of structured verdicts with conditions, adapted for delivery planning context.

### 7. Model: sonnet (not opus)

The agent is set to `sonnet` as specified in the request.

**Rationale per request**: Adversarial review benefits from comprehensive input (large context windows, reading multiple prior outputs) more than model depth. Sonnet handles multi-document synthesis effectively. Opus would be appropriate for novel architectural reasoning, but the QA/Critic is primarily applying adversarial lenses to existing content rather than generating novel technical analysis.

---

## Template Deviations

### Deviation 1: Two-paragraph identity opening

The template specifies "You are a {role description}. Your expertise covers {domain areas}." (single paragraph). The agent uses two paragraphs — one for role/expertise, one for behavioral mode.

**Rationale**: The adversarial framing is a behavioral mode constraint, not just expertise description. It warrants its own paragraph to ensure it registers as a distinct identity constraint, not a sub-point under expertise.

### Deviation 2: Output report has 8 sections instead of template's format sections

The template shows a simple report structure. The QA/Critic output has 8 named sections (Executive Assessment, Assumptions Challenged, Gaps Identified, Estimate Stress Test, Risk Escalations, Testability Review, Kill Criteria, Verdict).

**Rationale**: These 8 sections directly map to the success criteria in the task brief (P5.13). Collapsing them into fewer sections would make the structured output machine-readable by the orchestrator harder, and would reduce the enforced completeness of the critique.

### Deviation 3: Diagnostics include `novel_gaps_found` counter

The standard diagnostic template does not include a `novel_gaps_found` field. This agent adds it.

**Rationale**: The primary pipeline success criterion for QA/Critic is finding at least one novel gap. The diagnostic must capture whether this was achieved so the orchestrator can verify the gate was met. This follows the pattern of extending diagnostics with role-specific metrics (Architect adds `components_identified`, `trade_offs_analyzed`; Eng Lead adds `critical_path_length`).

---

## Line Count

Agent file: approximately 260 lines. Within the acceptable ~300 limit given the 8-section output template requirement.
