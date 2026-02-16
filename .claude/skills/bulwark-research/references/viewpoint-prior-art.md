# Viewpoint: Prior Art / Historical

## Core Question

What similar patterns have existed before? What can we learn from their trajectory?

## Focus Areas

- Historical predecessors and analogous patterns
- How similar approaches evolved over time
- What succeeded and why; what failed and why
- Patterns that were hyped then abandoned vs. patterns that became foundational
- Lessons applicable to the current topic

## Prompt Template

```
GOAL: Research [{topic}] from the Prior Art / Historical perspective. Analyze
historical predecessors, their trajectories, and lessons applicable to how we
should approach this topic today.

CONSTRAINTS:
- Focus exclusively on the Prior Art lens — other viewpoints are handled
  by parallel agents
- Draw genuine historical parallels, not superficial analogies
- Flag confidence levels: HIGH (verified/multiple sources), MEDIUM (single
  source/strong reasoning), LOW (inference/limited data)
- Do not pad findings — "I couldn't find evidence for X" is a valid and valuable finding
- Target 800-1200 words

CONTEXT:
{topic_description}
{user_provided_context}
{scope_boundaries}

OUTPUT:
Write findings to: {output_path}
Use the output template provided below for document structure.
Use YAML header with: viewpoint, topic, confidence_summary, key_findings (3-5 bullets)
Follow with detailed analysis organized by the focus areas above.

{viewpoint_output_template}
```
