# Anti-Patterns

Five recurring failure modes for spec drift checks. Every one of these has been observed in real Bulwark and CLEAR-framework sessions. Each entry: title, what it looks like, why it harms, what to do instead.

---

## 1. Skipping Step 1 (Claim Extraction)

**What it looks like**: The orchestrator reads the spec, forms a mental model, and starts verifying based on memory of what the spec said. No numbered checklist is produced.

**Why it harms**: Embedded claims (a paragraph mid-section, a footnote, a path inside a YAML example) get missed. The verifier checks the load-bearing top-level claims but silently skips the rest. Drift in those un-extracted claims surfaces during implementation as "wait, this file doesn't exist" — the most expensive moment to discover drift.

**What to do instead**: Always produce the numbered checklist explicitly. The checklist is the only mechanical way to enforce coverage. See `step-1-claim-extraction.md` for the procedure.

---

## 2. Verifying After Implementation Starts

**What it looks like**: The orchestrator skims the spec, starts coding, and runs verification "as needed" when something looks off mid-implementation. No upfront drift check; the spec is consumed as truth.

**Why it harms**: Drift caught mid-implementation = wasted work. The half-implemented deliverable now has to be unwound (or worse, kept and patched), the scope must be re-estimated mid-flight, and the user's mental model of the WP is broken. The 7-step methodology exists precisely to front-load this cost.

**What to do instead**: Run spec-drift-check at Stage 0 of the WP, before any implementation work. Per SD1 (the Bulwark rule shipping in P10.20), this is mandatory at WP start. Drift is cheaper to surface upfront than mid-flight.

---

## 3. Treating Handoff / Memory as Immutable Truth

**What it looks like**: The spec references a session handoff ("per S119 handoff, P10.18 is in_progress") or a memory entry ("per `feedback_skill_leanness`, skills should be lean"). The orchestrator reads the reference and accepts it without checking whether the referenced state still holds.

**Why it harms**: Handoffs and memory entries are snapshots. By the time another session runs, the snapshot may be stale. P10.18 may have shipped; the memory entry may have been amended. Treating them as immutable truth means the verifier inherits stale assumptions and ships work against a state that no longer exists.

**What to do instead**: When a claim references a handoff or memory entry, open the entry and verbatim-quote the relevant text into the verification log's `actual_state` field. If the entry no longer says what the spec claims, flag the drift. Snapshots are evidence, but only fresh evidence is verifiable evidence.

---

## 4. Recalling Claims Rather Than Grep-Quoting Verbatim

**What it looks like**: The verifier writes "I recall the function `foo` is at `bar.ts:42`" without re-Grepping. Or the verifier paraphrases what the spec says ("the spec basically asserts X is at Y") and verifies the paraphrase.

**Why it harms**: Recall hallucinates. Confidently. The verifier will write "CONFIRMED" with a fabricated location, and the finding will look identical to a real CONFIRMED in the log. The drift surfaces only when the implementer goes to make the change and finds nothing where the verifier said something existed. Recall is the silent failure mode that defeats the entire methodology.

**What to do instead**: Grep + verbatim quote, every time. If a claim references a function, run `Grep` for the function name and capture the matched line in the verification log. If a claim references a handoff, Read the handoff file and quote the relevant text directly. Never paraphrase, never recall — these are non-negotiable per the BINDING checklist.

---

## 5. Auto-Applying Drift Fixes Without User Sign-Off (Scope Changes)

**What it looks like**: The orchestrator runs the audit, finds a HIGH-severity DRIFT-undeclared-scope, silently adds the new deliverable to the adjusted plan, and proceeds to implementation. No AskUserQuestion fires; the user sees the verdict only after the work is done.

**Why it harms**: Scope expansions need explicit user sign-off — that's the entire point of the STOP_USER_APPROVAL verdict. Auto-applying a HIGH finding violates the user's contract: they asked for the WP-as-spec, not the WP-as-spec-plus-whatever-the-verifier-thought-was-needed. The user loses control of scope; future sessions inherit a plan that diverges from the spec without an audit trail of why.

**What to do instead**: For every HIGH finding, fire AskUserQuestion (per `step-6-decision-matrix.md`'s template) before binding the adjusted plan. The user gets explicit options: approve the adjustment, reject and keep the original spec, or request more detail. Document the user's decision in the log's `decision_rationale:` field. STOP_USER_APPROVAL is not a suggestion — it's a hard gate.

---

## Quick Reference Table

| # | Anti-Pattern | Severity if violated | Detection signal |
|---|--------------|---------------------|------------------|
| 1 | Skipping Step 1 | High (drift caught late) | No numbered claim checklist in the log |
| 2 | Verifying mid-implementation | High (wasted work) | Implementation work starts before Stage 5 log writes |
| 3 | Handoff / memory as immutable truth | Medium (stale assumptions) | `actual_state` field references the spec's reference, not a fresh quote |
| 4 | Recall vs grep-quote | High (fabricated CONFIRMED) | `actual_state` field is a paraphrase or "I recall ..." rather than a verbatim quote |
| 5 | Auto-applying HIGH findings | High (scope drift) | Adjusted plan binds without an AskUserQuestion fire for HIGH findings |
