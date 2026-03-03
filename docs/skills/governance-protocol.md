# governance-protocol

Injects the Bulwark governance rules into Claude's context at the start of every session.

## Invocation and usage

This skill is not user-invoked. It is an internal infrastructure skill that loads automatically at session start.

### Auto-invocation

The `inject-protocol.sh` script is configured as a `SessionStart` hook in `hooks/hooks.json`. When a new Claude Code session begins, the hook runs the script, which reads `skills/governance-protocol/SKILL.md` and outputs its content directly into Claude's active context. No user action is required. Manually invoking `/the-bulwark:governance-protocol` is not supported and has no defined behavior.

## Who is it for

- Anyone who has installed The Bulwark. The skill fires for every session automatically.
- Projects that rely on Rules.md being enforced from the first message of each session, not just when explicitly loaded.
- Teams where consistent enforcement across sessions matters more than per-session opt-in.

## How it works

At session start, the hook outputs the protocol content to Claude's context. Claude reads it as part of its session instructions before responding to any user message.

The protocol does three things:

- **Displays an activation banner.** Claude outputs a fixed confirmation banner so you can see that governance is active.
- **Binds Rules.md.** The protocol instructs Claude that Rules.md is a non-negotiable contract for the session. Skill compliance rules (SC1-SC3), testing rules (T1-T4), verification rules (V1-V4), and coding standards (CS1-CS4) all apply from the first message onward.
- **Establishes quality gates.** PostToolUse hooks run typecheck, lint, and build checks after every write or edit. The protocol tells Claude to expect these checks and to treat failures as blockers, not warnings.

The skill also includes an optional `## Project-Specific Rules` section at the bottom of `SKILL.md`. Projects can add custom governance rules there. Those rules are injected alongside the core protocol content on every session start.
