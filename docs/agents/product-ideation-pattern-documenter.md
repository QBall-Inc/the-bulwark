# product-ideation-pattern-documenter

Analyzes competitive data to document success and failure patterns, competitor trajectories, and opportunity gaps. Produces a pattern report grounded in evidence from the competitive analysis.

**Model:** claude-sonnet

## Invocation

This is a Tier 3 agent. It is spawned exclusively by the [product-ideation](../skills/product-ideation.md) skill during Stage 3 of the pipeline. It runs in parallel with the [segment-analyzer](product-ideation-segment-analyzer.md) agent.

Do not invoke it directly. It requires the competitive analysis log written by the [competitive-analyzer](product-ideation-competitive-analyzer.md) in Stage 2, a structured idea brief, and an output path. All of these are provided by the product-ideation orchestrator. Without this context, the agent lacks the input it needs to extract meaningful patterns.

To evaluate a product idea through the full pipeline:

```
/the-bulwark:product-ideation <idea-description>
```

## What it does

The agent reads the competitive analysis log in full before starting any analysis. It does not re-profile individual competitors. Instead, it extracts meta-lessons: what the successful competitors have in common, what the failed ones got wrong, and where those patterns open gaps that a new entrant can exploit.

For each success and failure pattern, the agent names it concisely, describes the mechanism in 2-3 sentences, and backs it with at least one specific competitor example from the analysis. A minimum of 3 success patterns and 3 failure patterns are required. If the competitive analysis lacks sufficient detail for a pattern, the agent runs targeted web searches to supplement, covering failure post-mortems, growth stories, and market-level success factors. Patterns without evidence are excluded. The output closes with an opportunity gap table that rates each gap as Strong, Moderate, or Speculative and maps it to the proposed idea.

## Output

All output is written to `logs/` in the project directory.

| File | Contents |
|------|----------|
| `logs/product-ideation-patterns-{timestamp}.md` | Success patterns (min. 3), failure patterns (min. 3), competitor trajectory profiles for 3-5 major players, opportunity gap analysis table |
| `logs/diagnostics/product-ideation-pattern-documenter-{timestamp}.yaml` | Execution metadata: web searches conducted, pattern counts, top success pattern, top failure risk, top opportunity gap |

A brief summary (100-150 tokens) is returned to the orchestrator on completion, covering pattern counts, the top success pattern, the top failure risk, and the highest-rated opportunity gap.
