# AT Teammate Prompt Structure (--exploratory mode)

This reference defines the mandatory prompt sections for Agent Teams teammates in `--exploratory` mode. Load this file at Stage 3B only.

---

## Prompt Sections

Each teammate prompt MUST include these sections:

**1. Role instructions** — from the corresponding `references/role-*.md` file

**2. Input context** — problem statement, research synthesis (if available), SME output

**3. Dual-Output Contract (SA2 — MANDATORY in every teammate prompt):**

> You MUST produce TWO outputs:
>
> **Output 1 — Full analysis (SA2 artifact):** Write your complete analysis to `$PROJECT_DIR/logs/brainstorm/{topic-slug}/{NN}-{role-slug}.md` using the output template provided. This is the permanent record.
>
> **Output 2 — Coordination summary (mailbox):** After writing your full analysis, send a 3-5 sentence summary to other teammates via sendMessage. Include: your recommendation (proceed/modify/defer/kill), your top finding, and your strongest concern.

**4. Peer Debate Directives:**

> **Selective challenge protocol:** After receiving summaries from other teammates:
> - Read each teammate's summary
> - If you DISAGREE with a position, send a targeted challenge via sendMessage explaining WHY you disagree with evidence
> - If you AGREE, do NOT send a message (avoid noise)
> - You may update your log file after the debate if your position changed — append a "## Post-Debate Update" section

**5. AT Mitigation Patterns (ALL 4 MANDATORY in every teammate prompt):**

> **CC-ALL:** When sending peer DMs with challenges, findings, or coordination signals, you MUST CC every other teammate (including the lead). Peer DMs without full-team CC are invisible to non-recipients and will be treated as stalled work. Format: include `CC: <Teammate-A>, <Teammate-B>, Lead` at the top of the message. CC-ALL replaces the prior CC-to-lead pattern — every participant sees every cross-cutting peer message in real time.
>
> **Task list coordination:** Update your task status to mark progress. Set to completed when your full analysis is written AND you have reviewed all peer summaries.
>
> **Completion signal:** When you have finished all work (analysis written, peer summaries reviewed, challenges sent if any), send a final message to the lead: "WORK COMPLETE — [role name]"
>
> **Confirmation handshake:** After sending WORK COMPLETE, the lead will reply with a confirmation request asking whether you have incorporated ALL inbound debate feedback. Reply `YES` only if you are fully complete; reply `NO` if still iterating. Do NOT silently re-engage after a `YES` — if you receive a late peer DM, signal another WORK COMPLETE and the lead will re-confirm.

**6. Critical Analyst — special AT directive (in addition to standard Critic prompt):**

> **Deferred verdict:** You are active from the start of the debate, not a sequential gatekeeper. Challenge early findings from other teammates as they arrive. However, do NOT form your final verdict until all teammates have shared their summaries. Your formal verdict belongs in your log artifact, not in peer messages. In your log file, include a "## Debate Influence" section documenting which peer positions you challenged and how the debate shaped your final verdict.

---

## AT Configuration (Hardcoded)

| Setting | Value | Rationale |
|---------|-------|-----------|
| Display mode | In-process | WSL2 safe default |
| Lead mode | Delegate | Coordination only — lead does not do analysis |
| Communication | Selective challenge | Broadcast summary once, respond only to disagreements |
| Teammate count | 3 | Fixed for v1 |

---

## Lead Coordination Gates (Lead MUST enforce)

The lead enforces these gates BEFORE beginning synthesis. Synthesis-too-early is the most common AT failure mode; these gates exist to prevent it.

### Work-Complete Confirmation Gate (MANDATORY)

When a teammate sends `WORK COMPLETE`, do NOT mark them terminal. Instead:

1. Send the following DM to that teammate, CC all other teammates:
   > "Confirm: have you incorporated ALL inbound debate feedback from this round? Reply YES when fully complete, NO if still iterating."
2. Await explicit `YES` response.
3. Only after receiving `YES` mark the teammate as terminal.
4. If the teammate replies `NO` or does not respond within the timeout, treat them as active — do NOT begin synthesis.

**Reason**: teammates often send `WORK COMPLETE` at initial draft, then iterate on peer feedback. Without this gate, synthesis excludes post-debate outcomes.

### Re-Entry Gate (MANDATORY)

If a teammate who previously confirmed `YES` sends any new peer DM, new WORK COMPLETE signal, or new content, mark them as **re-active** and require a fresh confirmation handshake (repeat the Confirmation Gate). The previous confirmation is **invalidated**.

**Reason**: a teammate may confirm done, then re-engage after receiving a late peer DM. Without re-entry handling, the late iteration is missed.

### Rendezvous Gate (synthesis precondition)

The lead MUST NOT begin synthesis until ALL of the following are true:

1. WORK COMPLETE + explicit `YES` confirmation received from ALL teammates (per Confirmation Gate)
2. All shared task list tasks in terminal state
3. All teammate log files exist and are non-empty
4. **Quiet period of 30 seconds** with NO new peer DM activity AND NO re-active teammates. If any new activity lands during the quiet period, reset the 30s timer and re-evaluate the Confirmation Gate for any re-active teammate.

---

## AT Failure Recovery

- **Teammate fails mid-debate**: Fall back to Stage 3A for the failed role only. Partial AT output from successful teammates feeds into fallback as additional context.
- **All teammates fail**: Fall back to full Stage 3A (--scoped pipeline).
- **Lead context compaction**: Known platform limitation. Structural mitigation: SME runs before AT (reduces lead context pressure). Document in diagnostics if observed.
