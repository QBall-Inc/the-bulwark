# Agent Teams vs Sequential Task Tool — Empirical Comparison

Identical problem statement ("webhook notification system with configurable delivery targets and retry logic") run through the plan-creation skill in both modes against the same codebase (PM-Essentials).

- **TC1**: Task tool mode (Session 78) — sequential sub-agents, orchestrator synthesizes
- **TC3**: Agent Teams mode (Session 80) — peer debate between Architect, Eng Lead, QA/Critic

## Side-by-Side Results

| Dimension | TC1 (Task Tool) | TC3 (Agent Teams) | Winner |
|-----------|-----------------|-------------------|--------|
| **Workpackages** | 13 WPs across 4 phases | 12 WPs across 6 phases | TC3 — cleaner phase boundaries |
| **Session estimate** | 19-22 (stressed: 33-43) | 9-14 | TC3 — dramatically tighter, more realistic |
| **Risks identified** | 6 (1 high, 4 medium, 1 low) | 7 (2 critical, 3 high, 2 medium) | TC3 — more honest severity ratings |
| **Kill criteria** | 5 (some vague) | 5 (all measurable) | TC3 — concrete thresholds |
| **Critic gaps** | 8 (G1-G8) | 7 (G1-G7) | Comparable — both thorough |
| **CLEAR integration** | Critic found the gap; plan adopted "explicit invocation" workaround | Critic found the gap; plan added WP11 (pipeline integration hook) | TC3 — addressed the gap structurally rather than deferring |
| **Technical findings** | curl dependency, secret sanitization, NFR1 contradiction | tsconfig/fetch incompatibility, WSL2/NTFS atomic rename, event deduplication, secrets bootstrapping | TC3 — codebase-verified findings, environment-aware |
| **Critic modifications incorporated** | 5 modifications | 8 modifications, 3 deferred with rationale | TC3 — more modifications actually landed in the plan |

## The Key Difference: Feedback Loop

In TC1 (Task Tool):
- The Critic identified that the Architect's `fetch` recommendation was wrong, that the Eng Lead's WP5 contradicted the Architect, and that there was no production caller
- But the Architect and Eng Lead **never got a chance to respond**. The orchestrator had to synthesize and resolve contradictions itself
- Result: the plan adopted workarounds (explicit invocation, deferred v2) rather than structural fixes

In TC3 (Agent Teams):
- The Critic challenged the Architect on `fetch` — the Architect **conceded** and the plan switched to `node:https`
- The Critic flagged the DLQ atomicity issue — the Eng Lead **updated** the approach to append-only JSONL
- The Critic flagged "no production caller" — a **new WP11** was added, not just documented as a gap
- Config inheritance contradiction was **reconciled in real-time** (append + `inherit_global: false` opt-out)

The TC1 synthesis says "5 modifications incorporated." The TC3 synthesis says "8 modifications incorporated." But the quality of incorporation is the real gap — TC3's modifications are structural (new WP, changed HTTP library, changed file format) while TC1's are mostly documentation-level (redefined NFR1, unified log format, added sanitization rule).

## Verdict: AT Mode Empirically Added Value

Peer debate produced:

1. **Richer technical corrections** — codebase-verified findings that fed back into the plan
2. **Structural plan changes** — new workpackages, not just footnotes
3. **Tighter estimates** — 9-14 sessions vs 19-22 (stressed 33-43) because contradictions were resolved before estimation, not discovered after
4. **Higher confidence outputs** — fewer "deferred to v2" items because issues were addressed in-flight
