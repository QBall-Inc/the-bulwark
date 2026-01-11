# The Bulwark - Reference Resources

External resources referenced during planning. Use these to adopt existing patterns rather than starting from scratch.

---

## Sub-Agent Prompting & Orchestration

| Resource | Use For | Key Patterns |
|----------|---------|--------------|
| [Loki Mode Skill](https://github.com/asklokesh/claudeskill-loki-mode/blob/main/SKILL.md) | P0.1, P0.2, P0.3 | 4-part template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT), task completion reports, model selection |
| [F# Pipeline Post](https://www.reddit.com/r/ClaudeCode/comments/1q3ogs5/) | P0.3 | F# pipe syntax for agent chaining, conditional branching, parallel conceptual execution |

---

## Official Anthropic Resources

| Resource | Use For | Key Patterns |
|----------|---------|--------------|
| [Anthropic Plugin Dev](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev) | P0.6, all phases | Official plugin structure, hook patterns, skill format |
| [Anthropic Skills Repo](https://github.com/anthropics/skills) | P0.6, skill creation | Official skill examples and patterns |

---

## Skill Enhancement & Continuous Feedback

| Resource | Use For | Key Patterns |
|----------|---------|--------------|
| [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers/tree/main/src/skill_seekers/cli) | P0.5 | enhance_skill.py patterns, backup/restore, quality checks |
| [Skill Seekers - enhance_skill.py](https://github.com/yusufkaraaslan/Skill_Seekers/blob/main/src/skill_seekers/cli/enhance_skill.py) | P0.5 | Staged workflow (Read→Analyze→Generate→Backup→Save→Review) |

---

## Testing & Bug Magnet Data

| Resource | Use For | Key Patterns |
|----------|---------|--------------|
| [Bug Magnet AI Assistant](https://github.com/gojko/bugmagnet-ai-assistant/) | P3.3 | Edge case data injection, test heuristics |
| [ArXiv Paper 2510.01171v3](https://arxiv.org/html/2510.01171v3) | P1.x, P3.x | Testing patterns, quality assessment |

---

## Existing Skill Collections (Adopt/Reference)

| Resource | Use For | Key Patterns |
|----------|---------|--------------|
| [Awesome Claude Skills](https://github.com/ComposioHQ/awesome-claude-skills) | All phases | Curated skill examples |
| [Ordinary Claude Skills](https://github.com/Microck/ordinary-claude-skills) | All phases | Community skill patterns |
| [Superpowers](https://github.com/obra/superpowers) | P3.x, P4.x | Agent patterns |
| [Pommel](https://github.com/dbinky/Pommel) | P0.x | Context management, hybrid search |

---

## Just Command Runner

| Resource | Use For | Key Patterns |
|----------|---------|--------------|
| [Just + Claude Code Reddit](https://www.reddit.com/r/ClaudeCode/comments/1pnfwtq/claude_code_just_is_a_game_changer_save_context/) | P2.1, P2.2 | Justfile patterns, token economy, cross-platform |

---

## Local References

| Resource | Location | Use For |
|----------|----------|---------|
| Gemini Research | `research/ClaudeCode-devworkflow-plugin.md` (in clear-framework) | Architecture, defense-in-depth model, rollout strategy |

---

## Task-to-Reference Mapping

| Task | Primary References |
|------|-------------------|
| P0.1 subagent-prompting | Loki Mode, F# Pipeline Post |
| P0.2 subagent-output-templating | Loki Mode (task completion reports) |
| P0.3 pipeline-templates | F# Pipeline Post, Loki Mode |
| P0.4 issue-debugging | Loki Mode (validation loops) |
| P0.5 continuous-feedback | Skill Seekers enhance_skill.py |
| P0.6 anthropic-validator | Anthropic Plugin Dev, Anthropic Skills Repo |
| P1.x test/verification | Bug Magnet, ArXiv paper |
| P2.x just integration | Just Reddit post |
| P3.3 bug-magnet-data | Bug Magnet AI Assistant |
| P3.x/P4.x agents/skills | Awesome Claude Skills, Ordinary Claude Skills, Superpowers |

---

## How to Use References

1. **Before implementing a task**, check this file for relevant references
2. **Review the reference** to understand existing patterns
3. **Adopt patterns** that fit, modify where needed for Bulwark's requirements
4. **Document deviations** from reference patterns in the implementation plan
