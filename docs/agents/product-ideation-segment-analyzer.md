# product-ideation-segment-analyzer

Identifies target user segments, builds Jobs-to-be-Done personas, estimates willingness to pay, and breaks down the TAM/SAM/SOM by segment.

## Model

Sonnet.

## Invocation guidance

**Tier 3: Pipeline-only.** This agent is spawned automatically by the [product-ideation](../skills/product-ideation.md) skill. It does not accept standalone invocation.

It runs in Stage 3, in parallel with the [pattern-documenter](product-ideation-pattern-documenter.md). Both agents read the competitive analysis report produced in Stage 2. The segment analyzer requires that report to identify which user types competitors already serve and, by contrast, where underserved segments exist. Without it, there is no evidence base for persona differentiation or willingness-to-pay estimates.

**Via parent skill:**

```
/the-bulwark:product-ideation <idea-description>
/the-bulwark:product-ideation --doc <path-to-idea-file>
```

## What it does

The agent reads the competitive analysis log in full before conducting any new research. It extracts which user types each competitor targets, what pricing models they use (a proxy for willingness to pay), where competitors are weak, and which segments no competitor focuses on. From this, it proposes 2-4 distinct user segments, each differentiated on at least two of: job to be done, budget, organization size, technical sophistication, or vertical.

For the top 2-3 segments, the agent develops a full JTBD persona covering functional, social, and emotional jobs, the current solution in use, the specific event that would drive a switch, and a willingness-to-pay estimate grounded in web research. Research signals include comparable tool pricing, forum discussions, survey data, and job postings. Persona claims are not invented from parametric knowledge alone.

After developing personas, the agent breaks down the SAM from market research into a per-segment table showing estimated user count, WTP range, and annual revenue potential. It identifies the primary segment based on the highest combination of size, willingness to pay, and underservedness, and maps each segment against the market gap identified in the competitive analysis.

## Output

All output is written to `logs/` in the project directory.

| File | Contents |
|------|----------|
| `logs/product-ideation-segments-{timestamp}.md` | Segment overview table, JTBD persona profiles with WTP estimates, segment-level SAM breakdown, segment-to-market-gap mapping, sources |
| `logs/diagnostics/product-ideation-segment-analyzer-{timestamp}.yaml` | Execution metadata: web searches conducted, segments identified, personas developed, primary segment, TAM estimate for primary segment, output path |

A brief summary (100-150 tokens) is returned to the orchestrator on completion, covering segment count, persona count, the primary segment name with estimated users and WTP range, and the report path.
