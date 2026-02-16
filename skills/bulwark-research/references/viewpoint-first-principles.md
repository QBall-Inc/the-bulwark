# Viewpoint: First Principles

## Core Question

What core problem does this solve? What is the minimal viable version?

## Focus Areas

- The fundamental problem being addressed (stripped of buzzwords)
- Why existing approaches are insufficient
- The minimal set of capabilities needed to solve the core problem
- What can be deferred vs. what is essential
- Decomposition into independent sub-problems

## Prompt Template

```
GOAL: Research [{topic}] from First Principles. Break it down to the fundamental
problem it solves, identify the minimal viable version, and decompose into
independent sub-problems.

CONSTRAINTS:
- Focus exclusively on the First Principles lens — other viewpoints are handled
  by parallel agents
- Strip away buzzwords and marketing — focus on the underlying problem
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
