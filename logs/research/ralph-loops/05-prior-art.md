---
viewpoint: prior-art
topic: Ralph Loops
confidence_summary:
  high: 7
  medium: 5
  low: 3
key_findings:
  - Ralph Loops descend directly from REPL (1958) and multi-pass compilers - iterative refinement with fresh state per iteration
  - Agent Teams vs Ralph mirrors 45-year tension between actor model coordination (1973) and single-process iteration
  - Unix pipes (1964), PDCA quality cycles (1920s-1950s), and TDD (late 1990s) all prefigure the Ralph pattern
  - WSL2/tmux constraints echo 1980s terminal multiplexing solving identical resource limitation problems
  - Ralph creators show no historical self-awareness - pattern emerged organically, not from studying predecessors
---

# Ralph Loops — Prior Art / Historical

## Summary

Ralph Loops represent a convergence of at least five distinct historical lineages: REPL interactive development (1958), multi-pass compiler architecture (1960s+), Unix composability philosophy (1964), quality control iteration cycles (1920s-1950s), and Test-Driven Development (late 1990s). The pattern emerged in December 2025 without explicit reference to these predecessors, suggesting parallel evolution rather than conscious inheritance. The Ralph vs Agent Teams tension recapitulates a 45-year debate between coordinated multi-agent systems (actor model, 1973) and optimized single-loop refinement.

## Detailed Analysis

### 1. REPL (Read-Eval-Print Loop) — The Direct Ancestor

**Confidence**: HIGH
**Evidence**: [Wikipedia - REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), [Lisp REPL History](https://mikelevins.github.io/posts/2020-12-18-repl-driven/)

Ralph's most direct historical ancestor is the REPL (Read-Eval-Print Loop), which originated in Lisp development at MIT in 1958 when Steve Russell implemented the first Lisp interpreter on the IBM 704. The expression "READ-EVAL-PRINT cycle" was formally documented by L. Peter Deutsch and Edmund Berkeley in a 1964 PDP-1 Lisp implementation, with Joseph Weizenbaum describing a REPL-based language just one month later.

The structural parallel is exact:
- **REPL**: Read input → Evaluate → Print result → Loop (fresh state)
- **Ralph**: Read task → Execute with AI → Write result to markdown → Loop (fresh context window)

Both patterns solve the same fundamental problem: **maximizing the "smart zone" of a constrained computational resource**. In 1958, the constraint was IBM 704 memory. In 2025, the constraint is Claude's context window. Geoffrey Huntley's insight that "tight tasks + 1 task per loop = 100% smart zone context utilization" directly echoes 60 years of REPL philosophy: small, focused interactions yield better results than monolithic execution.

**Application to Bulwark Skills**: The `continuous-feedback` skill is essentially a REPL for quality enforcement. Each tool invocation triggers fresh evaluation with updated state.

### 2. Multi-Pass Compiler Architecture — Iterative Refinement with Intermediate State

**Confidence**: HIGH
**Evidence**: [Multi-pass Compiler - Wikipedia](https://en.wikipedia.org/wiki/Multi-pass_compiler), [Compiler Design Tutorial](https://www.tutorialspoint.com/compiler_design/compiler_design_architecture.htm)

Multi-pass compilers, formalized in the 1960s and documented comprehensively in the "Dragon Book" ([Compilers: Principles, Techniques, and Tools](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)), provide the architectural blueprint for Ralph's approach:

1. **Pass 1** (Lexical Analysis): Source code → Token stream
2. **Pass 2** (Syntax Analysis): Token stream → Abstract Syntax Tree
3. **Pass 3** (Semantic Analysis): AST → Annotated AST
4. **Pass 4+** (Optimization): Annotated AST → Improved AST (iterative)
5. **Final Pass** (Code Generation): Optimized AST → Machine code

Each pass takes the previous pass's output as input, improving it incrementally. Ralph's IMPLEMENTATION_PLAN.md serves the exact same role as compiler intermediate representations: **persistent state between otherwise isolated iterations**.

The "eventual consistency achieved through iteration" described in the [Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook) is precisely how multi-pass compilers achieve optimizations that would be impossible in a single pass. Early compilers like PECAN (1980s, developed by Steven P. Reiss) pioneered incremental compilation that only reprocessed changed sections - a direct parallel to Ralph's task-by-task iteration.

**Application to Bulwark Skills**: `code-review` and `test-audit` implement multi-pass architecture - Stage 1 (discovery) feeds Stage 2 (deep analysis) feeds Stage 3 (synthesis).

### 3. Unix Pipes and Composability — McIlroy's Garden Hose (1964)

**Confidence**: HIGH
**Evidence**: [Unix Philosophy - Wikipedia](https://en.wikipedia.org/wiki/Unix_philosophy), [Kafka, Samza, and Unix Philosophy](https://martin.kleppmann.com/2015/08/05/kafka-samza-unix-philosophy-distributed-data.html)

Doug McIlroy invented the Unix pipe in 1964 with the vision of "connecting programs like a garden hose - screw in another segment when it becomes necessary to massage data in another way." His 1978 formalization - "Make each program do one thing well" and "Expect the output of every program to become the input to another" - is the philosophical foundation for Ralph.

Key principles that carry forward:
- **Uniform interfaces**: Unix programs use stdin/stdout. Ralph uses markdown files (IMPLEMENTATION_PLAN.md, PRD.md)
- **Idempotency**: Unix tools produce the same output given the same input. Ralph iterations are deterministic given the same task + context
- **Composability**: `cat file | grep pattern | sort | uniq` chains simple operations. Ralph chains AI iterations with test/build validation between each

The [Harvard CS overview](https://cscie2x.dce.harvard.edu/hw/ch01s06.html) notes: "you can re-run the same command as many times as you want, and gradually iterate your way towards a solution." This is Ralph's core loop.

**Application to Bulwark Skills**: `skill-creator` and `agent-creator` implement composable pipelines where proposal → validation → refinement stages chain via intermediate artifacts.

### 4. TDD Red-Green-Refactor — Kent Beck's Iterative Discipline (Late 1990s)

**Confidence**: HIGH
**Evidence**: [Test-Driven Development - Wikipedia](https://en.wikipedia.org/wiki/Test-driven_development), [Martin Fowler - TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html)

Kent Beck codified Test-Driven Development in his 2002 book *Test-Driven Development by Example*, building on Extreme Programming practices from the late 1990s. The red-green-refactor cycle maps directly to Ralph's workflow:

- **Red** (write failing test) → Ralph: Define task acceptance criteria
- **Green** (make it pass, commit sins) → Ralph: AI implements solution
- **Refactor** (eliminate duplication) → Ralph: Review/validate, iterate if needed

Beck's inspiration came from reading 1970s books about typing expected output before writing programs - an early form of specification-driven development. Ralph operationalizes this at scale: the PRD.md is the "expected output tape," and each iteration validates against it.

The [ralph-native.sh gist](https://gist.github.com/fredflint/588d865f98f3f81ff8d1dc8f1c7c47de) explicitly references TDD: "Write failing test FIRST (see RED)" and "Implement minimum code to pass (see GREEN)."

**Application to Bulwark Skills**: All Bulwark skills using `bulwark-implementer` follow TDD discipline - test-first, minimum viable implementation, validation before completion.

### 5. PDCA Cycle — Shewhart and Deming's Quality Control (1920s-1950s)

**Confidence**: MEDIUM
**Evidence**: [PDCA - Wikipedia](https://en.wikipedia.org/wiki/PDCA), [ASQ - PDCA Cycle](https://asq.org/quality-resources/pdca-cycle)

The Plan-Do-Check-Act cycle originated with physicist Walter Shewhart at Bell Labs in the 1920s, then was popularized by W. Edwards Deming in 1950s Japan as the foundation of continuous quality improvement. Ralph implements PDCA at the task level:

- **Plan**: Define task in PRD.md, specify acceptance criteria
- **Do**: Execute task via AI agent
- **Check**: Run tests, validate against "Linus's criteria"
- **Act**: Mark complete or iterate with feedback

The iterative nature is explicit in PDCA philosophy: "once a hypothesis is confirmed (or negated), executing the cycle again will extend the knowledge further." Ralph's "learnings-capture" mechanism mirrors Deming's emphasis on documenting insights from each cycle.

**Application to Bulwark Skills**: `bulwark-verify` implements PDCA - plan (verification protocol), do (test execution), check (results analysis), act (mark fixed or iterate).

### 6. Actor Model and Supervision Trees — Multi-Agent Coordination (1973)

**Confidence**: HIGH
**Evidence**: [Actor Model - Wikipedia](https://en.wikipedia.org/wiki/Actor_model), [History of Actors](https://eighty-twenty.org/2016/10/18/actors-hopl)

The debate between Ralph Loops (single-agent iteration) and Agent Teams (multi-agent coordination) recapitulates a 45-year tension in distributed systems.

The actor model was introduced in 1973 by Carl Hewitt at MIT as "a universal modular actor formalism for artificial intelligence." Key insight: actors receive messages, process independently, and send messages to other actors - no shared state. Erlang (1980s, Ericsson) operationalized this with OTP supervision trees for fault-tolerant telecommunications systems.

**Ralph vs Agent Teams maps exactly to this historical debate**:

| Pattern | Historical Analog | Coordination | State Management | Failure Mode |
|---------|------------------|--------------|------------------|--------------|
| Ralph Loops | Single-process iteration (Make, compilers) | Sequential, centralized | Shared markdown files | Fail-stop, retry loop |
| Agent Teams | Actor model, Erlang OTP | Parallel, distributed | Independent context windows | Supervisor restarts failed agents |

The [Agent Teams research paper](https://arxiv.org/html/2602.01465v2) cites "TRAE" and "Prometheus" as fixed-pipeline multi-agent approaches (mid-2020s), but the architectural pattern goes back to Hewitt's 1973 formalization.

**When to use which** (historical lessons):
- **Single-loop refinement** (Ralph): Sequential dependencies, same-file edits, resource-constrained environments (see §7)
- **Multi-agent coordination** (Teams): Parallel exploration, competing hypotheses, cross-layer changes

**Application to Bulwark Skills**: `bulwark-research` uses Agent Teams pattern (5 parallel Sonnet viewpoints). `bulwark-brainstorm` uses hybrid (5 sequential Opus roles, but could parallelize).

### 7. Terminal Multiplexing and Resource Constraints — tmux/Screen (1980s)

**Confidence**: MEDIUM
**Evidence**: [tmux - Wikipedia](https://en.wikipedia.org/wiki/Tmux), [Terminal Multiplexer History](https://medium.com/@rabiagondur/terminal-multiplexers-screen-or-tmux-7e757da81cf1)

Terminal multiplexers emerged in the 1980s to solve resource constraints on shared Unix systems where users connected via RS-232 serial lines to mainframes. GNU Screen (1987, Oliver Laumann) and tmux (2007, Nicholas Marriott) enabled multiple virtual terminal sessions within a single physical connection.

**WSL2/tmux Ralph deployments face identical constraints**:
- **1980s**: Limited physical terminals, expensive RS-232 connections, shared CPU/memory
- **2025**: Limited context windows, expensive API costs, shared WSL2 resources

The [Agent Teams documentation](https://code.claude.com/docs/en/agent-teams) explicitly recommends tmux for split-pane mode: "tmux has known limitations on certain operating systems and traditionally works best on macOS." This echoes 40 years of tmux wisdom about platform-specific quirks.

**Historical lesson for WSL2**: tmux's history buffer (default 2000 lines, configurable) parallels Claude's context window. Just as tmux users learned to set appropriate history limits for resource-constrained systems, Ralph deployments must tune task sizes for Claude's "smart zone" limits.

**Application to Bulwark Skills**: Bulwark's SA5 rule (no `run_in_background: true` for sub-agents) reflects this historical lesson - background processes dump full transcripts into parent context, causing "token spikes" just as tmux background jobs can overflow history buffers.

### 8. CI/CD Feedback Loops — Modern Evolution (2000s-Present)

**Confidence**: MEDIUM
**Evidence**: [IBM - CI/CD Pipeline](https://www.ibm.com/think/topics/ci-cd-pipeline), [2026 CI/CD Revolution](https://medium.com/@sajitharasathurai2/the-2026-ci-cd-revolution-predictive-automated-kubernetes-native-e164d8157cb4)

Continuous Integration (early 2000s) and Continuous Deployment (mid-2010s) formalized the feedback loop pattern for software delivery. By 2026, CI/CD has evolved to include AI-driven test generation and production-based testing with defects fed back into pipelines.

**Ralph operationalizes CI/CD at the task level**:
- **Build**: AI generates code
- **Test**: Automated validation (tests, lint, typecheck)
- **Deploy**: Commit to version control
- **Monitor**: Capture learnings, update PRD.md

The [BrowserStack CI/CD guide](https://www.browserstack.com/guide/difference-between-continuous-integration-and-continuous-delivery) emphasizes "faster insights into build failures" - exactly what Ralph's tight loops provide. Each iteration is a mini-CI/CD cycle.

**Application to Bulwark Skills**: `continuous-feedback` is literal CI/CD - PostToolUse hooks trigger quality gates after every code modification.

### 9. Control Theory and PID Loops — Engineering Feedback (1911-Present)

**Confidence**: LOW
**Evidence**: [PID Controller - Wikipedia](https://en.wikipedia.org/wiki/Proportional%E2%80%93integral%E2%80%93derivative_controller), [NI - PID Theory](https://www.ni.com/en/shop/labview/pid-theory-explained.html)

PID (Proportional-Integral-Derivative) controllers, first developed by Elmer Sperry in 1911, use feedback loops to iteratively adjust system behavior toward a setpoint. The 1942 Ziegler-Nichols tuning rules formalized how to set optimal gain parameters.

**Loose parallel to Ralph**:
- **P** (proportional): Adjust based on current error → Ralph's immediate validation feedback
- **I** (integral): Account for accumulated error → Ralph's learnings capture across iterations
- **D** (derivative): Anticipate future error → Ralph's acceptance criteria and planning

This analogy is weaker than others because Ralph doesn't use mathematical control theory, but the **philosophical pattern is identical**: measure deviation from goal (setpoint = PRD requirements), apply correction (AI iteration), repeat until error is minimized (task complete).

**Application to Bulwark Skills**: Weak parallel. Bulwark skills don't implement true PID control, but the verify-correct-reverify pattern in `bulwark-verify` echoes feedback control.

### 10. Autonomous Agent Evolution — Recent History (2023-2026)

**Confidence**: HIGH
**Evidence**: [AutoGPT/BabyAGI History](https://medium.com/@roseserene/agentic-ai-autogpt-babyagi-and-autonomous-llm-agents-substance-or-hype-8fa5a14ee265), [SWE-bench](https://openai.com/index/introducing-swe-bench-verified/)

Ralph emerged from the rapid evolution of autonomous coding agents:

- **March 2023**: AutoGPT released (Toran Bruce Richards), 100K+ GitHub stars in months
- **April 2023**: BabyAGI released (Yohei Nakajima) - simple task manager loop with GPT-4
- **Late 2023**: Consolidation into frameworks (LangChain, LlamaIndex)
- **2024-2025**: SWE-bench benchmarking shows gap between demos and production readiness (23% success rate on SWE-bench Pro vs 70% on verified tasks)
- **December 2025**: Ralph methodology emerges, emphasizing simplicity over complexity

**Key historical lesson**: The [Rise and Fall of Autonomous Agents article](https://medium.com/@lukas.kowejsza/the-rise-and-fall-of-autonomous-agents-18360625067e) documents how early 2023 autonomous agent hype ("AutoGPT will replace developers!") collapsed when real-world performance proved inadequate. Ralph represents a pragmatic retreat to bounded, validated iteration rather than unbounded autonomy.

**Application to Bulwark Skills**: Bulwark's OR1 rule (implementation always by Opus-class model) and verification gates reflect this lesson - quality over autonomy.

### 11. OODA Loop — Military Decision-Making (1970s)

**Confidence**: LOW
**Evidence**: [OODA Loop - Wikipedia](https://en.wikipedia.org/wiki/OODA_loop), [Military History](https://www.mca-marines.org/gazette/ooda-loop-for-strategy/)

Colonel John Boyd developed the OODA loop (Observe-Orient-Decide-Act) in the early 1970s after analyzing Korean War air combat. Boyd argued that success came from rapid iteration through this cycle faster than opponents.

**Mapping to Ralph**:
- **Observe**: Read task, current state
- **Orient**: Understand context, prior learnings
- **Decide**: Plan implementation approach
- **Act**: Execute, validate, document

The OODA loop has been applied to DevOps and agile development, but the connection to Ralph is indirect. It's more a general framework for iterative decision-making than a specific technical pattern.

**Application to Bulwark Skills**: Weak parallel. The `bulwark-research` skill's multi-viewpoint approach loosely mirrors "orient" (understand from multiple perspectives), but OODA doesn't map cleanly to code generation workflows.

### 12. Make and Incremental Builds — Dependency-Driven Iteration (1976)

**Confidence**: MEDIUM
**Evidence**: [Incremental Compilation](https://mattrickard.com/incremental-compilation-build-systems), [Make Dependency Graphs](https://faouellet.github.io/bst-dg/)

Make (Stuart Feldman, 1976) pioneered dependency graphs for incremental builds - only recompile files that changed or depend on changed files. Modern incremental compilers extend this: "even if only a single function is modified, the entire file goes through the full compilation pipeline again" in traditional systems, but advanced incremental compilation tracks finer-grained dependencies.

**Ralph's task dependencies** (blockedBy chains in PRD.md) implement a Make-like dependency graph. The sequential task execution mirrors Make's topological sort of the dependency graph.

**Historical lesson**: Make succeeded because it made builds **repeatable** and **cacheable**. Ralph applies the same principle to AI workflows - markdown files serve as the "Makefile" declaring dependencies and state.

**Application to Bulwark Skills**: All Bulwark pipeline skills use dependency chains - Stage 2 depends on Stage 1 output, Stage 3 depends on Stage 2, etc.

## Confidence Notes

### LOW Confidence Findings

**PID Control Theory**: The parallel is philosophically interesting (feedback loops, error minimization) but technically weak. Ralph doesn't implement mathematical control - it's a metaphor, not a model.

**OODA Loop**: While OODA has been applied to DevOps, the connection to Ralph is circumstantial. Many iterative frameworks could claim OODA ancestry.

**Historical Self-Awareness**: I found **zero evidence** that Ralph creators studied any of these patterns. The [Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook) and gists show no citations to REPL, compilers, Unix philosophy, or PDCA. This suggests **parallel evolution** - Ralph reinvented patterns that worked in other domains. Confidence is LOW on whether these connections influenced Ralph's design vs. being post-hoc observations.

### What Would Increase Confidence

- Interview with Geoffrey Huntley about inspirations
- Earlier drafts or internal docs showing design evolution
- Evidence of whether Ralph creators knew about REPL, multi-pass compilers, or Unix pipes
- Comparative analysis of Ralph with other 2025-era autonomous coding patterns (did others also converge on bash loops?)

## Cross-Objective Synthesis

### Objective 1: What are Ralph Loops?

**Historical answer**: Ralph Loops are a 2025 reinvention of REPL (1958) + multi-pass compilers (1960s) + Unix pipes (1964), applied to AI context window constraints. They descend from a 60+ year tradition of iterative refinement with fresh state per iteration.

### Objective 2: Application to Bulwark Skills

| Skill | Historical Pattern | Specific Parallel |
|-------|-------------------|-------------------|
| `continuous-feedback` | REPL, CI/CD | Each tool call triggers fresh evaluation loop |
| `skill-creator` | Unix pipes, multi-pass compilation | Proposal → validation → refinement stages |
| `agent-creator` | Unix pipes, actor model | Composable agent definitions with message-passing |
| `code-review` | Multi-pass compilation | 4-stage pipeline (discover → analyze → refine → synthesize) |
| `test-audit` | TDD, PDCA | Red (gaps) → Green (suggest tests) → Refactor (review) |
| `bulwark-research` | Actor model, OODA | 5 parallel agents (observe from 5 orientations) |
| `bulwark-brainstorm` | PDCA, TDD | Sequential roles iterate through Plan-Do-Check-Act |

### Objective 3: Ralph Loops vs Agent Teams

**Historical context**: This is the **1973 actor model vs single-process iteration debate** playing out in AI workflows.

- **Ralph** inherits from: REPL, Make, multi-pass compilers (single-process, sequential, shared state)
- **Agent Teams** inherits from: Actor model (1973), Erlang OTP (1980s), supervision trees (parallel, distributed, independent state)

**When history suggests each pattern**:
- Ralph for: Sequential dependencies (Make), same-artifact refinement (compiler optimization passes), resource constraints (tmux/Screen history)
- Agent Teams for: Parallel exploration (actor model), competing hypotheses (OODA orient phase), fault tolerance (Erlang supervision)

### Objective 4: WSL2/Tmux Considerations

**Historical lesson**: WSL2/tmux Ralph deployments face the **exact same constraints as 1980s terminal multiplexing** - limited resources, shared systems, need for session persistence.

**Lessons from tmux/Screen history**:
1. **Tune history buffer size** (tmux default 2000 lines) → Ralph equivalent: tune task size for context window
2. **Avoid background job overflow** (fills history buffer) → Bulwark SA5: no `run_in_background: true`
3. **Platform-specific quirks** (tmux works better on macOS) → WSL2-specific testing required
4. **Session detach/reattach** (core tmux feature) → Ralph's markdown persistence enables equivalent "detach" (stop loop) and "reattach" (resume from PRD.md state)

## Sources

- [Ralph Playbook by Geoffrey Huntley](https://github.com/ClaytonFarr/ralph-playbook)
- [Ralph Loop Agent by Vercel Labs](https://github.com/vercel-labs/ralph-loop-agent)
- [Agent Teams Research Paper](https://arxiv.org/html/2602.01465v2)
- [Official Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
- [Read-Eval-Print Loop - Wikipedia](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
- [REPL-Driven Development by Mikel Evins](https://mikelevins.github.io/posts/2020-12-18-repl-driven/)
- [Multi-pass Compiler - Wikipedia](https://en.wikipedia.org/wiki/Multi-pass_compiler)
- [Compiler Design Architecture Tutorial](https://www.tutorialspoint.com/compiler_design/compiler_design_architecture.htm)
- [Test-Driven Development - Wikipedia](https://en.wikipedia.org/wiki/Test-driven_development)
- [Martin Fowler - Test Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Unix Philosophy - Wikipedia](https://en.wikipedia.org/wiki/Unix_philosophy)
- [Kafka, Samza, and Unix Philosophy - Martin Kleppmann](https://martin.kleppmann.com/2015/08/05/kafka-samza-unix-philosophy-distributed-data.html)
- [Harvard CS - Unix Philosophy Basics](https://cscie2x.dce.harvard.edu/hw/ch01s06.html)
- [PDCA - Wikipedia](https://en.wikipedia.org/wiki/PDCA)
- [ASQ - PDCA Cycle](https://asq.org/quality-resources/pdca-cycle)
- [Actor Model - Wikipedia](https://en.wikipedia.org/wiki/Actor_model)
- [History of Actors - Eighty-Twenty](https://eighty-twenty.org/2016/10/18/actors-hopl)
- [Erlang Actor Model - BerB Diploma Thesis](https://berb.github.io/diploma-thesis/original/054_actors.html)
- [tmux - Wikipedia](https://en.wikipedia.org/wiki/Tmux)
- [Terminal Multiplexers: Screen or Tmux - Rabia Gondur](https://medium.com/@rabiagondur/terminal-multiplexers-screen-or-tmux-7e757da81cf1)
- [PID Controller - Wikipedia](https://en.wikipedia.org/wiki/Proportional%E2%80%93integral%E2%80%93derivative_controller)
- [NI - PID Theory Explained](https://www.ni.com/en/shop/labview/pid-theory-explained.html)
- [CI/CD Pipeline - IBM](https://www.ibm.com/think/topics/ci-cd-pipeline)
- [2026 CI/CD Revolution - Medium](https://medium.com/@sajitharasathurai2/the-2026-ci-cd-revolution-predictive-automated-kubernetes-native-e164d8157cb4)
- [BrowserStack - CI vs CD Guide](https://www.browserstack.com/guide/difference-between-continuous-integration-and-continuous-delivery)
- [Agentic AI: AutoGPT, BabyAGI - Medium](https://medium.com/@roseserene/agentic-ai-autogpt-babyagi-and-autonomous-llm-agents-substance-or-hype-8fa5a14ee265)
- [Rise of Autonomous Agents - BairesDev](https://www.bairesdev.com/blog/the-rise-of-autonomous-agents-autogpt-agentgpt-and-babyagi/)
- [SWE-bench Verified - OpenAI](https://openai.com/index/introducing-swe-bench-verified/)
- [SWE-Bench Pro - Scale AI](https://scale.com/leaderboard/swe_bench_pro_public)
- [OODA Loop - Wikipedia](https://en.wikipedia.org/wiki/OODA_loop)
- [History of OODA Loop - i-nexus](https://blog.i-nexus.com/the-history-of-the-ooda-loop/)
- [Incremental Compilation in Build Systems - Matt Rickard](https://mattrickard.com/incremental-compilation-build-systems)
- [Building a Build System: Dependency Graph](https://faouellet.github.io/bst-dg/)
- [Loop Optimizations - Johnny's Software Lab](https://johnnysswlab.com/loop-optimizations-how-does-the-compiler-do-it/)
- [Context Window Limitations - Medium](https://medium.com/@gianluca.mondillo/context-window-the-memory-limits-of-llms-f11887390490)
- [LLM Context Windows - Redis](https://redis.io/blog/llm-context-windows/)
