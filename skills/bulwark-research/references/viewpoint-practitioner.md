# Viewpoint: Practitioner Perspective

## Core Question

How do teams actually use this in production? What works and what doesn't?

## Focus Areas

- Real-world adoption patterns — who uses this and how
- Common implementation approaches and their trade-offs
- Practical gotchas that documentation doesn't cover
- Operational concerns (debugging, monitoring, maintenance)
- Team skill requirements and learning curves

## Prompt Template

```
GOAL: Research [{topic}] from the Practitioner Perspective. Describe how teams
actually use this in production — what works well, what's harder than expected,
and what operational concerns arise.

CONSTRAINTS:
- Focus exclusively on the Practitioner lens — other viewpoints are handled
  by parallel agents
- Draw on real-world usage patterns, not theoretical capabilities
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
