---
viewpoint: Prior Art / Historical
topic: "Claude Code Agent Teams — Multi-Agent Orchestration Patterns"
confidence_summary:
  high: 6
  medium: 5
  low: 2
key_findings:
  - "Agent Teams' filesystem-as-blackboard coordination directly recapitulates HEARSAY-II (1971-1976): shared workspace, independent specialist 'knowledge sources', file-based state. The architecture is 50 years old — the LLM-powered knowledge sources are new."
  - "FIPA (1997-2005) attempted standardized agent communication protocols and failed due to brittle symbolic semantics. Agent Teams' mailbox system succeeds where FIPA failed because LLMs interpret natural-language messages adaptively, eliminating the ACL brittleness problem."
  - "Anthropic's own benchmarks show multi-agent systems outperform single-agent by 90.2% but consume 15x more tokens. Coordination overhead grows super-linearly (exponent 1.724), capping effective team size at 3-4 agents — consistent with mob programming's empirical 4-5 person optimum."
  - "Ralph Loops and Agent Teams are independent historical lineages: Ralph descends from REPL/TDD/continuous integration (iterative single-agent verification), while Agent Teams descend from blackboard systems and distributed AI (parallel multi-agent coordination). They solve different problems and can coexist."
  - "WSL2/tmux is not an arbitrary constraint — it follows the container/isolation evolution path (chroot 1979 → LXC 2008 → Docker 2013 → tmux-pane isolation 2026). Constrained environments historically improve safety and reproducibility at the cost of coordination complexity, which is exactly the tradeoff Agent Teams document explicitly."
---

# Agent Teams — Prior Art / Historical

## Summary

Claude Code Agent Teams are architecturally a 21st-century implementation of the blackboard systems pattern first realized in HEARSAY-II (1971-1976), upgraded with LLM-powered knowledge sources, a filesystem-native shared workspace, and natural-language agent communication that resolves the symbolic brittleness that killed FIPA's 1997-2005 standardization effort. The history of multi-agent systems is a story of the right architecture arriving before the right substrate: blackboards needed LLMs, actor models needed cheap isolated processes, and FIPA needed semantically flexible communication — all of which are now available. Agent Teams also inherits performance constraints confirmed across every prior generation: coordination overhead grows super-linearly with team size, and teams of more than 4-5 agents reliably underperform smaller, more focused configurations.

## Detailed Analysis

### Direct Historical Predecessors

**Blackboard Systems (HEARSAY-II, 1971-1976)**

The closest and most direct predecessor is the blackboard architecture developed for the HEARSAY-II speech understanding system at Carnegie Mellon. The architecture consists of three components: (1) a global, hierarchical shared data structure (the "blackboard") that represents the current solution state; (2) independent specialist modules ("knowledge sources") that monitor the blackboard and contribute partial solutions; and (3) a control mechanism that determines which knowledge source activates next.

Agent Teams replicates this architecture with precision:
- The shared task list at `~/.claude/tasks/{team-name}/` is the blackboard
- Each teammate is a knowledge source with its own context window and specialization
- The team lead acts as the opportunistic scheduler (HEARSAY-II's "scheduler" component)
- The inbox at `~/.claude/teams/{team-id}/inbox/` is HEARSAY-II's inter-knowledge-source communication mechanism

HEARSAY-II succeeded at speech understanding. Its successor HASP/SIAP succeeded at sonar interpretation. The architecture was validated. What killed blackboard systems in the 1980s-90s was not architectural failure — it was implementation cost. Building specialized "knowledge sources" required extensive manual engineering. LLMs remove this cost entirely: each Claude teammate is a general-purpose knowledge source that can be role-specialized via prompt.

The "resurgence of blackboard systems" that researchers noted as a theoretical prediction has now materialized as Claude Code Agent Teams.

**Actor Model (Hewitt, 1973) and Erlang/OTP**

The Actor Model defines concurrent computation as actors: entities that process messages, create new actors, and send messages to other actors, with no shared mutable state. Erlang/OTP operationalized this into industrial-grade fault-tolerant systems (WhatsApp, RabbitMQ, Discord scale).

Agent Teams' teammate architecture maps directly: each teammate is an actor (owns its context, responds to messages, is addressed by identity), the mailbox system is the message-passing mechanism, and "no session resumption with in-process teammates" is the classic actor isolation tradeoff (isolation improves fault containment at the cost of state recovery complexity).

The critical Erlang lesson is supervision trees: processes are organized hierarchically, with supervisors restarting failed children. Agent Teams currently lacks automatic supervision — "teammates stopping on errors" is explicitly listed as a known limitation. Erlang resolved this in 1987. Agent Teams has not yet.

**BDI Agents and FIPA/JADE (1987-2005)**

The Belief-Desire-Intention model (Bratman 1987, Rao & Georgeff 1995) formalized agents as entities with beliefs about the world, desires (goals), and committed intentions (plans). JADE, JACK, and JADEX implemented BDI in Java. FIPA established standardized agent communication languages (ACL) for interoperability.

FIPA failed for a documented reason: symbolic ACL required explicit, unambiguous message semantics that brittle, handcrafted knowledge sources couldn't reliably honor. The FIPA community dissolved around 2005 with no major production adoption outside research.

Agent Teams solves this precisely: the mailbox system uses natural-language XML messages (`<teammate-message teammate_id="...">content</teammate-message>`), and each Claude instance interprets messages semantically. What FIPA needed was a universal natural-language parser that could resolve message intent without rigid ACL schemas. LLMs are that parser.

The BDI adoption failure also confirmed that pre-specified agent goals (desires) don't survive contact with dynamic environments. Agent Teams' "require plan approval" workflow — where the lead reviews and rejects plans before execution — is BDI's intention commitment mechanism, but with human-in-the-loop validation rather than fully autonomous commitment.

**Confidence**: HIGH
**Evidence**: HEARSAY-II architecture documented in Nii (1986) AI Magazine; Actor Model in Hewitt (1973); BDI in Rao & Georgeff (1995) ICMAS; FIPA dissolution and ACL limitations from research literature; Agent Teams architecture from official docs at code.claude.com/docs/en/agent-teams

---

### AI Multi-Agent Framework Evolution

**AutoGen, CrewAI, LangGraph, MetaGPT (2023-2025)**

The 2023-2025 LLM multi-agent framework generation provides the most directly applicable historical data:

*CrewAI* adopted a role-based model inspired by organizational structures — assigning agents as "Researcher", "Writer", "Editor". This is the same specialization principle as HEARSAY-II knowledge sources and is where Agent Teams' "spawn a security reviewer teammate" examples originate. Role-based specialization consistently outperformed unspecialized agents across frameworks.

*AutoGen* focused on conversational agent collaboration with code execution. The safety failure mode was documented: generated Python code accessing filesystems, shell commands, and unsafe imports in multi-agent contexts compounded security exposure. Agent Teams' permission inheritance from the lead addresses exactly this gap — teammates start with the lead's permission settings, preventing unauthorized escalation.

*LangGraph* introduced graph-based state machines for agent coordination. The key lesson: explicit state transitions are more reliable than implicit conversational coordination, but require upfront workflow design that limits flexibility.

*MetaGPT* used structured roles with SOP (standard operating procedure) documents — closest to Bulwark's CLAUDE.md-as-shared-context pattern. MetaGPT demonstrated that shared project context reduces hallucination and redundancy.

**The universal failure pattern**: coordination overhead outpacing coordination value. Research from 2024-2025 established:
- Communication overhead grows with an exponent of 1.724 (super-linear)
- Effective team size caps at 3-4 agents before coordination cost exceeds parallelization benefit
- In tool-heavy environments (>10 tools), efficiency drops 2-6x versus single agents
- Once single-agent baseline exceeds ~45% accuracy, adding agents yields diminishing returns

**What Agent Teams gets right that predecessors didn't**: the file-locking mechanism for task claiming prevents the race conditions that plagued earlier parallel agent implementations. Self-claiming tasks with atomic file locks is a distributed systems pattern (mutex/semaphore) applied to agent coordination — sound engineering absent from first-generation LLM frameworks.

**Confidence**: HIGH
**Evidence**: Framework comparisons from langcopilot.com, datacamp.com, galileo.ai; coordination overhead research from Google (research.google/blog/towards-a-science-of-scaling-agent-systems); Anthropic multi-agent benchmarks (anthropic.com/engineering/multi-agent-research-system); Agent Teams docs

---

### Organizational Theory Parallels

**Conway's Law (1967)** states that systems mirror the communication structure of the organizations that build them. The inverse: if you want a specific system architecture, structure the team to match it.

Agent Teams makes Conway's Law programmable: you specify the team structure in the spawn prompt and the resulting agent collaboration structure mirrors what you describe. "Spawn three reviewers — one security, one performance, one test coverage" produces a system whose output structure (three distinct review reports) mirrors the specified team structure.

The "Inverse Conway Maneuver" — restructuring the org to achieve a desired architecture — is exactly what Agent Teams' "delegate mode" accomplishes: restricting the lead to coordination-only forces the architecture toward genuine parallelism rather than sequential execution masquerading as parallel.

**Mob Programming (Zuill, 2014)** provides the closest organizational parallel to Agent Teams. Empirical studies show mob teams of 4-5 people produce significantly higher code quality than individual developers. The structural analogy is direct: mob programming = multiple humans, one keyboard (sequential access to the codebase); Agent Teams = multiple Claude instances, file-locked task claiming (sequential claim, parallel execution). Both solve the same problem — how do you get multiple minds working on the same codebase without conflicts and with shared understanding?

Agent Teams' "adversarial teammates" pattern (spawn agents to disprove each other's hypotheses) directly mirrors the "devil's advocate" role in mob programming retrospectives.

**Research shows small AI-augmented mob teams (4-5 humans sharing an AI) are currently the most productive structure found** — consistent with Agent Teams' documented performance ceiling of 3-4 agents before coordination overhead dominates.

**Confidence**: MEDIUM
**Evidence**: Conway's Law from Wikipedia and Martin Fowler bliki; Mob programming from Agile Alliance, Ståhl & Mårtensson (2021); organizational parallels from reynolds.co/blog/how-organizations-shape-their-agentic-systems; team size cap from Google research

---

### Success and Failure Patterns

Across the entire prior art lineage, three success factors and three failure factors emerge with consistent evidence:

**Success Factors:**

1. **Role specialization with independent context windows**: HEARSAY-II knowledge sources, CrewAI roles, Agent Teams teammates — all succeed because each specialist operates without context pollution from other specialists' work. This mirrors how senior engineers describe effective code review: "I can find security issues better when I'm not simultaneously tracking performance implications."

2. **Shared state with coordination protocol**: Blackboards, shared task lists with file locking, and Actor Model mailboxes all succeed because they provide a single source of truth that all agents can observe without direct coupling. The failure mode of shared mutable state (race conditions) is addressed by file locking in Agent Teams.

3. **Human oversight at key checkpoints**: Anthropic's internal research system shifted to "require plan approval" for complex tasks, finding that humans catching early architectural errors prevented catastrophic wasted effort downstream. Agent Teams formalizes this as the plan-approval workflow.

**Failure Factors:**

1. **Over-coordination**: AutoGen agents spawned 50 subagents for simple queries. Blackboard systems had opportunistic scheduling that triggered redundant knowledge sources. Agent Teams' current limitations warn about "lead shutting down before work is done" (opposite failure) but the over-coordination failure mode is documented in prior frameworks.

2. **Context loss across agent boundaries**: BDI agents' static belief sets, JADE's inability to update commitments dynamically, and modern LLM frameworks' context window fragmentation all produce the same failure: agents diverge from the shared understanding established earlier. Agent Teams addresses this by having teammates load CLAUDE.md — shared project context that persists across agent spawns.

3. **Infrastructure brittleness compounding agent errors**: The Agyn paper (arxiv 2602.01465v2) documents that legacy CI dependencies and deprecated components derailed multi-agent execution unrelated to code quality. Agent Teams' current limitation — "no session resumption with in-process teammates" — is the same pattern: infrastructure failure breaks the coordination model catastrophically rather than gracefully.

**Confidence**: HIGH
**Evidence**: Agyn paper (arxiv.org/html/2602.01465v2); Anthropic multi-agent research system post; AutoGen failure documentation; FIPA/BDI research literature

---

### Agent Teams vs Ralph Loops — Historical Lineages

These are demonstrably independent evolutionary lineages that solve orthogonal problems:

**Ralph Loops lineage**: REPL (1960s) → test-driven development (1980s-90s) → continuous integration (1999) → agentic CI (Ralph, 2024-2025). Core pattern: single agent, iterative feedback loop, automated verification criterion. Ralph is the LLM-native expression of "run until tests pass."

**Agent Teams lineage**: Blackboard systems (1971) → Distributed AI (1980s) → FIPA/JADE (1997-2005) → LLM multi-agent frameworks (2023-2025) → Claude Code Agent Teams (2025). Core pattern: multiple agents, shared workspace, parallel specialization. Agent Teams is the LLM-native expression of "HEARSAY-II with natural language knowledge sources."

These lineages have never merged in the historical record, and there is no documented evidence that combining them produces better outcomes than either alone. The Session 61 research confirmed that Ralph Loops are near-zero applicability for Bulwark's one-shot analysis and orchestrated pipeline architecture. Agent Teams targets a different problem domain entirely — parallel exploration and specialization — rather than iterative completion.

The Agyn paper provides one data point where a manager-mediated multi-agent system (Agent Teams lineage) used iterative rounds of feedback (Ralph lineage element) — but this was explicit iteration managed by the manager agent, not self-contained loops. Hybridization is theoretically possible but uncharted territory with no success cases documented.

For Bulwark's current architecture: the existing single-orchestrator model (Opus spawning Sonnet/Haiku sub-agents) is already effective. Agent Teams would add value only for tasks requiring genuine peer-to-peer coordination between specialists who need to challenge each other's findings — not for Bulwark's current sequential pipeline architecture.

**Confidence**: HIGH (lineage distinctness); LOW (hybridization analysis)
**Evidence**: Session 61 Ralph Loops synthesis (logs/research/ralph-loops/synthesis.md); ghuntley.com/loop/ for Ralph lineage; blackboard/FIPA literature for Agent Teams lineage; Agyn paper for manager-mediated iteration

---

### Constrained Environment Precedents

Agent Teams' reliance on tmux/iTerm2 for split-pane mode follows a well-documented historical trajectory:

**Container isolation history**: chroot (1979, Unix v7) → FreeBSD jails (2000) → Linux cgroups (2006, Google) → LXC (2008, IBM) → Docker (2013) → Kubernetes (2014). Each step in this lineage added coordination capability while preserving isolation guarantees. The consistent lesson: isolation improves safety and reproducibility; the cost is coordination complexity and recovery fragility.

tmux as an agent coordination layer is functionally equivalent to Docker's role in the early Kubernetes era: it provides process isolation and visibility (multiple panes = multiple agent views) without the overhead of full containerization. The documented limitation — "known limitations on certain operating systems, traditionally works best on macOS" — echoes Docker's early Linux-only constraints that made WSL2 adoption difficult.

WSL2 specifically creates a constrained execution environment where NTFS filesystem semantics (case-insensitivity, permission model) differ from native Linux. This is not unique to Agent Teams — it is the same constraint that required `git update-index --chmod=+x` for executable scripts in Bulwark (documented in MEMORY.md, Session 45). The historical parallel is early Java's "write once, run anywhere" promise encountering platform-specific filesystem behavior in the 1990s — isolation works until the substrate differs.

The practical implication: Agent Teams' in-process mode (no tmux required) is the architectural equivalent of Docker's move from requiring LXC to its own libcontainer in 2014 — eliminating an external dependency to improve portability. For WSL2, in-process mode is the safe starting point.

**Confidence**: MEDIUM
**Evidence**: Container history from aquasec.com/blog/a-brief-history-of-containers; Agent Teams tmux limitations from official docs; MEMORY.md WSL2 CRLF/executable bit findings from Sessions 45-61

---

### Evolution Trajectory

Historical patterns across all predecessor lineages converge on three trajectories for multi-agent AI systems:

**1. Protocol Standardization (replaying FIPA's success attempt, with better substrate)**

FIPA attempted to standardize agent communication in 1997. It failed because symbolic ACL semantics were too rigid. The same standardization attempt is now underway with better tools:
- Anthropic's MCP (Model Context Protocol) standardizes agent-to-tool communication
- Google's A2A (Agent-to-Agent Protocol) standardizes peer-to-peer agent messaging
- 50+ industry partners (Atlassian, Salesforce, SAP, etc.) have committed to A2A

This is FIPA's 1997 ambition finally realized with LLM-native semantics. Agent Teams' filesystem-based mailbox system is a pre-standardization protocol that will likely converge toward A2A as the field matures. Gartner projects 40% of enterprise applications will embed AI agents by end of 2026, creating market pressure for interoperability standards.

**2. Toward Flat Peer Coordination (from hierarchical orchestration)**

The current Bulwark model (single Opus orchestrator, Sonnet/Haiku workers) mirrors the hierarchical organizational structures that Conway's Law predicts systems will mirror. Agent Teams introduces direct peer messaging, moving toward the flatter coordination structures that Erlang/OTP demonstrated scale better for certain problem classes.

The A2A protocol explicitly enables "multiple peer agents coordinating through shared memory or messaging, with no single permanent controller." This mirrors the microservices evolution from monoliths (single orchestrator) through service mesh (peer-to-peer with coordination layer). The trajectory is toward emergent coordination rather than explicit hierarchical command.

However, research consistently shows that leaderless coordination fails for ill-structured problems (the blackboard systems lesson: opportunistic scheduling required a dedicated controller). The practical equilibrium will likely be "leader-optional" — hierarchical for ambiguous tasks, peer-to-peer for well-structured parallel work.

**3. Cost/Quality Calibration as a First-Class Concern**

Anthropic's own multi-agent research system was the first documented case where token economics were treated as an architectural constraint equivalent to correctness. "Simple queries need 1 agent with 3-10 tool calls; complex research uses 10+ subagents" is an explicit cost-scaling specification absent from all prior multi-agent literature.

The historical pattern: distributed computing systems (MapReduce, Kubernetes) took approximately 5-7 years from introduction to production-calibrated cost models. Multi-agent LLM systems are 2-3 years old. Expect the next 2-3 years to produce the equivalent of Kubernetes resource quotas and LimitRange — explicit cost governance for agent systems.

For Bulwark, this means the current evaluation of Agent Teams should weigh not just "does it work" but "at what token cost, and does that cost scale with project size?" The 15x token multiple is manageable for occasional research tasks; it is prohibitive for routine pipeline operations.

**Confidence**: MEDIUM (standardization trajectory, high confidence on FIPA parallel); LOW (leaderless coordination equilibrium prediction)
**Evidence**: A2A/MCP protocol emergence from ruh.ai/blogs/ai-agent-protocols-2026-complete-guide; Gartner 40% projection from computerweekly.com; Anthropic research system cost calibration from anthropic.com/engineering; Google scaling research from research.google/blog

---

## Confidence Notes

**LOW confidence findings requiring additional evidence:**

1. **Hybridization of Ralph Loops and Agent Teams**: The claim that combining iterative single-agent loops (Ralph) with parallel multi-agent teams (Agent Teams) is "uncharted territory" is based on absence of evidence from the search results, not positive evidence of failure. A dedicated search for hybrid architectures (e.g., "iterative multi-agent", "parallel Ralph", "self-correcting agent teams") could increase confidence. The Agyn paper's manager-mediated iteration is a partial data point but not a full hybrid system.

2. **"Leaderless coordination equilibrium" trajectory prediction**: The prediction that practical multi-agent systems will converge toward "leader-optional" coordination is an inference from the blackboard/Erlang/A2A trajectory, not a documented research finding. Evidence that would increase confidence: longitudinal studies of multi-agent system architectures in production (none yet exist, as the field is 2-3 years old).

**MEDIUM confidence findings with known gaps:**

- **Mob programming parallel**: The analogy between mob programming (4-5 humans) and Agent Teams (3-4 agents) is structurally sound but the empirical studies are from human teams. No direct study of optimal AI agent team size as a function of task type exists yet. The Google research (3-4 agent cap) is the closest data point but measures coordination overhead, not holistic performance.

- **WSL2 tmux constraints**: The container isolation history is well-documented, but the specific claim that in-process mode is the "Docker libcontainer equivalent" is an architectural analogy, not a tested claim. No empirical data on WSL2-specific Agent Teams behavior (beyond official docs noting tmux limitations) was found.

Sources consulted:
- [Claude Code Agent Teams official docs](https://code.claude.com/docs/en/agent-teams)
- [Agyn multi-agent paper](https://arxiv.org/html/2602.01465v2)
- [Anthropic multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Google: Towards a science of scaling agent systems](https://research.google/blog/towards-a-science-of-scaling-agent-systems-when-and-why-agent-systems-work/)
- [Blackboard system Wikipedia](https://en.wikipedia.org/wiki/Blackboard_system)
- [Agent Teams reverse-engineered technical architecture](https://vibecodecamp.blog/blog/how-to-install-and-use-claude-code-agent-teams-reverse-engineered)
- [Multi-agent framework comparison 2025](https://langcopilot.com/posts/2025-11-01-top-multi-agent-ai-frameworks-2024-guide)
- [MCP vs A2A protocol guide](https://ruh.ai/blogs/ai-agent-protocols-2026-complete-guide)
- [Container history](https://www.aquasec.com/blog/a-brief-history-of-containers-from-1970s-chroot-to-docker-2016/)
- [Conway's Law and agentic AI](https://medium.com/@josef-dijon/from-code-to-conway-architecting-the-future-with-agentic-ai-teams-3b4b1ebedc05)
- [LLM-Powered Swarms: A New Frontier or a Conceptual Stretch?](https://arxiv.org/abs/2506.14496)
- [BDI agent architecture — AAAI 1995](https://cdn.aaai.org/ICMAS/1995/ICMAS95-042.pdf)
