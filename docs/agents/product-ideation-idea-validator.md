# product-ideation-idea-validator

Assesses a product idea across four dimensions (feasibility, market timing, uniqueness, and problem-solution fit) and produces a PASS/CONDITIONAL/FAIL verdict backed by web research.

## Model

Sonnet.

## Invocation guidance

**Tier 3: Pipeline-only.** This agent is spawned automatically by the [product-ideation](../skills/product-ideation.md) skill. It does not accept standalone invocation.

It runs in Stage 1, in parallel with the market researcher, and receives a synthesized idea brief prepared by the orchestrator after the user interview. The verdict it produces gates further pipeline execution: a FAIL verdict causes the skill to pause and ask whether to continue or refine the idea before the competitive analyzer runs.

Attempting to invoke the agent outside the pipeline will produce incomplete output because it expects a structured prompt with a CONTEXT section, an analysis frameworks path, and an explicit output file path — all of which the orchestrator provides.

**Via parent skill:**

```
/the-bulwark:product-ideation <idea-description>
/the-bulwark:product-ideation --doc <path-to-idea-file>
```

## What it does

The agent evaluates the idea brief across four dimensions: technical feasibility (can this be built with available technology today), market timing (is this the right moment given current infrastructure and market maturity), uniqueness (does it occupy meaningful whitespace or is it incremental on an existing solution), and problem-solution fit (is the problem painful enough that people actively seek solutions, and does the proposed solution address the core pain).

Each dimension is scored independently using web research, not just parametric knowledge. A minimum of three searches are conducted: one for the problem category, one for existing products addressing it, and one for recent market signals such as funding announcements or shutdowns. For promising results, the agent fetches the full page. The final verdict is determined by a defined scoring table: PASS requires no fatal flaws across all four dimensions, CONDITIONAL allows one addressable weakness with documented conditions for resolution, and FAIL is issued when two or more dimensions score low or a single dimension reveals a structural flaw such as an identical dominant solution already in market.

## Output

| File | Contents |
|------|----------|
| `logs/product-ideation-idea-validation-{timestamp}.md` | Verdict (PASS/CONDITIONAL/FAIL), dimension scores with rationale, existing solutions found, market signals, top 3 strengths, top 3 concerns, verdict reasoning |
| `logs/diagnostics/product-ideation-idea-validator-{timestamp}.yaml` | Execution metadata: searches conducted, pages fetched, solutions found, output path |
