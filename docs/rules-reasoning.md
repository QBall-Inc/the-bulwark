# Rules Reasoning & Examples

Reference document preserving code examples, rationale, and historical context removed from Rules.md during P8.1 slimming. Never auto-loaded — consulted by humans when needed.

---

## T1: Never Mock the System Under Test — Code Examples

If testing that a proxy starts, **actually start a proxy**.

```typescript
// FORBIDDEN
jest.spyOn(child_process, 'spawn').mockReturnValue(mockProcess);
expect(child_process.spawn).toHaveBeenCalled();

// REQUIRED
const result = await startProxy();
expect(await checkPort(8096)).toBe(true);
```

## T2: Verify Observable Output — Code Examples

Tests verify **results**, not that functions were called.

```typescript
// FORBIDDEN: expect(db.save).toHaveBeenCalled();
// REQUIRED:  expect((await db.find(id)).status).toBe('active');
```

## V2: Use `just` for Execution — Code Examples

```bash
just test      # Not: npm test
just lint      # Not: npm run lint
just typecheck # Not: npx tsc
```

## Grounding Clause — Full Reference URLs

Every implementation must:

1. **Match Official Anthropic Guidelines** for hooks, agents, skills, and plugins
2. **Use only documented Claude Code patterns** - no undocumented behaviors

Reference documentation:
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills
- Sub-agents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Plugins: https://docs.anthropic.com/en/docs/claude-code/plugins

---

## Historical Context

- **T1-T4**: Added in P0 after observing Claude consistently mocking systems under test, producing tests that verified nothing.
- **V1-V4**: Added in P0 after Claude declared fixes "complete" without running them.
- **CS1-CS4**: Added in P0 to establish baseline code quality standards.
- **ID1-ID3**: Added in P0 to enforce root cause analysis before fixing.
- **OR1-OR4**: Added in P0, refined through P4. OR1 updated in P8.1 to reflect bulwark-implementer (Opus sub-agent for implementation). OR4 updated in P8.1 to support parallel execution per pipeline-templates.
- **SA1-SA6**: Added incrementally P0-P4. SA6 added in Session 45 after P4.4-2 testing validated presumed-execute behavior.
- **SC1-SC3**: Added after DEF-P4-005 (Session 40) — Claude was ignoring skill instructions without explicit binding language.
- **SR1-SR4**: Added in P0, refined through P3. Token checkpoints proven critical for session management.
- **TR1-TR3**: Added in P0. Task brief pattern validated across all phases.
