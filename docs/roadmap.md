# The Bulwark — Roadmap

This is a directional roadmap, not a commitment. There are no hard timelines, and
priorities shift with real-world feedback. The project follows
[Semantic Versioning](https://semver.org/). Have a request? [Open an issue](https://github.com/QBall-Inc/the-bulwark/issues).

**Latest stable release:** [v1.2.1](https://github.com/QBall-Inc/the-bulwark/releases/latest) — see the [CHANGELOG](../CHANGELOG.md) for full history.

---

## Next — v1.3.0 · *Fewer prompts, sharper reviews*

Developer-experience and correctness wins that build on the v1.2.x hardening
bundle.

- **Language-aware code review.** The code-review pipeline becomes polyglot —
  applying the right checks for Python, shell, and config files instead of
  assuming TypeScript. Type-safety and lint sections adapt to the language under
  review.
- **Fewer permission prompts.** Tool declarations across skills and agents, plus
  an opt-in hook that auto-approves The Bulwark's own bundled assets — so you
  spend less time clicking through permission dialogs for the plugin's own
  scripts.

## v1.4.0 · *Measure your assets*

Skills and agents are the new code layer in agentic development. They deserve the
same rigor — versioned, tested, measured.

- **Evaluation framework.** Two new skills — `create-skill-evals` and
  `run-skill-evals` — to generate and execute evaluations for any Claude Code
  asset. Define test prompts, expected outputs, and grading criteria; run them
  across versions to catch regressions.
- **Enhanced traceability.** Version, model, and rules-hash stamps in every
  sub-agent log, plus run manifests that tie a whole pipeline execution into a
  single auditable record.

## v1.5.0 · *Baselines & enterprise*

- **Asset baselines.** Versioned evaluation baselines for all skills and agents,
  so future changes are measured against a known-good reference automatically.
- **Standalone enterprise offering** *(exploratory)*. Evaluation and traceability
  that works independently of The Bulwark's rules/hooks — decision lineage, rules
  snapshots, and audit replay for teams. Still in the research phase.

---

## Exploring — no release assigned yet

These are on our radar but not yet scheduled. Order and inclusion may change.

- **Codebase & documentation understanding.** A skill for onboarding onto
  existing (brownfield) projects — priming a batch of sub-agents to parse and map
  a codebase before research and planning begin. *(Today, the brownfield workflow
  relies on manual sub-agent orchestration; this skill would formalize it.)*
- **Framework-specific Justfiles.** Auto-detect your stack (Next.js, Django,
  FastAPI, etc.) and scaffold tailored build/test/lint recipes.
- **Agent memory.** Persistent memory for sub-agents across invocations —
  remembering project conventions and recurring patterns.
- **Smarter pipeline routing.** Tighter review → fix → retest loops; when a
  review finds issues, route to fix validation automatically.
- **Security pattern updates.** A helper that keeps the test-audit pipeline's
  security coverage current without manual curation.

---

*Internal sequencing, dependencies, and effort estimates are tracked separately
by the maintainers.*
