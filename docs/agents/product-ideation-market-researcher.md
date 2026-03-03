# product-ideation-market-researcher

Researches market size, growth trends, key players, and regulatory landscape for a product idea. Produces a sourced market assessment with TAM/SAM/SOM estimates.

**Model:** claude-sonnet

## Invocation

This is a Tier 3 agent. It is spawned exclusively by the [product-ideation](../skills/product-ideation.md) skill during Stage 1 of the pipeline. It runs in parallel with the [idea-validator](product-ideation-idea-validator.md) agent.

Do not invoke it directly. It requires a structured idea brief, a reference to `analysis-frameworks.md`, and an output path. All of these are provided by the product-ideation orchestrator. Without this context, the agent lacks the inputs it needs to produce a coherent output.

To run market research on a product idea, invoke the parent skill:

```
/the-bulwark:product-ideation <idea-description>
```

## What it does

The agent translates a product idea brief into 2-3 market category names, then conducts a minimum of 5 web searches across market size, growth trends, recent funding signals, and key players. Market size is estimated using both top-down (industry reports narrowed by geography and segment) and bottom-up (unit economics: users x ACV x capture rate) approaches. Data recency is flagged explicitly. If no data newer than 2022 is found, the agent notes the gap rather than silently relying on stale figures.

After sizing the market, the agent runs a PESTLE assessment across all six factors and rates each as Favorable, Neutral, or Unfavorable for market entry. Key players are listed by name and stage only. Competitive depth is deliberately out of scope here — that work belongs to the competitive-analyzer in Stage 2.

## Output

All output is written to `logs/` in the project directory.

| File | Contents |
|------|----------|
| `logs/product-ideation-market-research-{timestamp}.md` | Market size estimates (TAM/SAM/SOM/CAGR), growth trends, key players overview, PESTLE assessment, sources list |
| `logs/diagnostics/product-ideation-market-researcher-{timestamp}.yaml` | Execution metadata: searches conducted, pages fetched, sources cited, data gaps, TAM estimate, market phase |

A brief summary (100-150 tokens) is returned to the orchestrator on completion, covering market category, TAM, CAGR, market phase, player count, and PESTLE blockers.
