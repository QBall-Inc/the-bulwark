# Viewpoint: Contrarian Angle

## Core Question

What failure modes and risks do most people overlook?

## Focus Areas

- Failure modes that advocates rarely mention
- Scenarios where this approach is the wrong choice
- Hidden costs (complexity, maintenance burden, cognitive load)
- Alternatives that might be simpler or more appropriate
- When NOT to use this

## Prompt Template

```
GOAL: Research [{topic}] from the Contrarian Angle. Identify failure modes,
hidden costs, and scenarios where this approach is the wrong choice. Challenge
the prevailing narrative.

CONSTRAINTS:
- Focus exclusively on the Contrarian lens — other viewpoints are handled
  by parallel agents
- Be genuinely critical, not performatively contrarian — ground critiques in evidence
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
