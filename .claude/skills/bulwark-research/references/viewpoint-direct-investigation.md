# Viewpoint: Direct Investigation

## Core Question

What is this? How does it work? What is the current state of the art?

## Focus Areas

- Define the concept precisely — what it is and what it is not
- How it works mechanically (architecture, data flow, lifecycle)
- Current state of the art — who uses it, what tooling exists
- Official documentation, specifications, or standards
- Key terminology and taxonomy

## Prompt Template

```
GOAL: Research [{topic}] from the Direct Investigation perspective. Produce a
comprehensive technical analysis covering definition, mechanics, state of the art,
and key terminology.

CONSTRAINTS:
- Focus exclusively on the Direct Investigation lens — other viewpoints are handled
  by parallel agents
- Be evidence-based: cite sources, examples, or reasoning for each claim
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
