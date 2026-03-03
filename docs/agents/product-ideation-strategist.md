# product-ideation-strategist

Synthesizes all five prior pipeline outputs into a BUY/HOLD/SELL recommendation with confidence level, strategic rationale, and actionable next steps.

## Model

Sonnet.

## Invocation guidance

**Tier 3: Pipeline-only.** This agent is spawned automatically by the [product-ideation](../skills/product-ideation.md) skill. It does not accept standalone invocation.

It runs in Stage 4, the final stage, after all five research agents have completed. The recommendation is grounded in the full research corpus: idea validation verdict, market size estimates, competitive intelligence, success and failure patterns, and segment economics. Without those five prior outputs, the agent has no evidence base to synthesize from, and standalone invocation produces no meaningful result.

**Via parent skill:**

```
/the-bulwark:product-ideation <idea-description>
/the-bulwark:product-ideation --doc <path-to-idea-file>
```

## What it does

The agent reads all five prior log files in sequence and extracts the key signals relevant to the recommendation: the idea validator's PASS/CONDITIONAL/FAIL verdict and dimension scores, the market researcher's TAM/SAM/SOM estimates and PESTLE ratings, the competitive analyzer's Porter's Five Forces assessment and market gap findings, the pattern documenter's success and failure pattern matches, and the segment analyzer's primary segment with willingness-to-pay estimates.

It then applies defined BUY/HOLD/SELL threshold criteria from the analysis frameworks reference. For a BUY, three gates must pass (market size, competitive gap, timing) and four of six amplifiers must be met. Mixed criteria result in a HOLD with a documented re-evaluation horizon. Fundamental issues result in a SELL with adjacent opportunity identification. The recommendation is exactly one of BUY, HOLD, or SELL. Confidence is exactly one of High, Medium, or Low. High confidence requires sourced data and a complete pipeline. Low confidence means material gaps exist in the evidence.

The final report is written as a standalone document suitable for someone who has not read the prior logs. Every assertion is tied to evidence from a specific pipeline stage.

## Output

| File | Contents |
|------|----------|
| `logs/product-ideation-strategy-{timestamp}.md` | Full strategy report: executive summary with recommendation upfront, SWOT synthesis, BUY/HOLD/SELL section with rationale, risk factors table with likelihood and impact ratings, actionable next steps |
| `logs/diagnostics/product-ideation-strategist-{timestamp}.yaml` | Execution metadata: inputs read, BUY gates met, amplifiers met, SWOT item count, recommendation, confidence, report path |
