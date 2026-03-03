# product-ideation-competitive-analyzer

Profiles direct and indirect competitors, investigates failed competitors, applies Porter's Five Forces, and identifies whether a genuine market gap exists for a product idea.

## Model

Sonnet.

## Invocation guidance

**Tier 3: Pipeline-only.** This agent is spawned automatically by the [product-ideation](../skills/product-ideation.md) skill. It does not accept standalone invocation.

It runs in Stage 2, after the market researcher and idea validator have completed. The agent reads the market research log to extract key players and market context before conducting its own competitor searches. Without that prior output, it has no grounding for which competitors to investigate or what market sizing has already been established.

Attempting to invoke the agent outside the pipeline will produce incomplete output because it expects a structured prompt with a CONTEXT section containing the market research log path, an idea brief, and an explicit output file path. All of these are provided by the orchestrator.

**Via parent skill:**

```
/the-bulwark:product-ideation <idea-description>
/the-bulwark:product-ideation --doc <path-to-idea-file>
```

## What it does

The agent begins by reading the market research log from Stage 1 to extract the market category, key players already identified, and any PESTLE blockers noted. It uses this as a starting point for targeted competitor searches, not as an exhaustive list. Profiles are built from web searches and page fetches covering positioning, pricing, customer reviews, funding, and scale. At minimum, three direct competitors and two failed competitors are profiled with specific evidence. Indirect competitors and substitutes are noted where relevant.

Failure analysis goes beyond identifying that a company shut down. The agent searches for post-mortems, pivot announcements, and shutdown coverage to identify the specific reason for failure: wrong segment, pricing mismatch, timing, execution failure, or displacement by a better-funded incumbent. Each failure case produces a concrete lesson for the idea under evaluation.

Porter's Five Forces is applied to assess the structural attractiveness of the industry. Each of the five forces is rated Low, Medium, or High based on the evidence gathered. The count of High-rated forces determines an overall attractiveness verdict: 0-1 High forces indicates an attractive industry, 4-5 indicates an unattractive one. The agent then assesses whether a genuine market gap exists: a clear segment, use case, or capability that existing competitors do not serve well, and whether that gap is structurally persistent rather than temporary.

## Output

All output is written to `logs/` in the project directory.

| File | Contents |
|------|----------|
| `logs/product-ideation-competitive-analysis-{timestamp}.md` | Porter's Five Forces ratings with evidence, direct competitor profiles (positioning, pricing, stage, strengths, weaknesses), indirect competitors, failed competitor analysis with lessons, market gap assessment |
| `logs/diagnostics/product-ideation-competitive-analyzer-{timestamp}.yaml` | Execution metadata: web searches conducted, pages fetched, direct and failed competitors profiled, industry attractiveness verdict, market gap verdict, report path |

A brief summary (100-150 tokens) is returned to the orchestrator on completion, covering the number of competitors profiled, industry attractiveness, market gap finding, and the top competitor's key weakness.
