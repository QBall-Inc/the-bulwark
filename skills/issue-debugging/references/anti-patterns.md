# Debugging Anti-Patterns

Common debugging mistakes that waste time and reduce fix reliability. Avoid these patterns.

---

## Anti-Pattern Checklist

Before debugging, review this checklist to avoid common traps:

### Pre-Fix Anti-Patterns

| Anti-Pattern | Symptoms | Correct Approach |
|--------------|----------|------------------|
| **Shotgun Debugging** | Making random changes, "try this and see" | Form hypothesis first, then test it |
| **Premature Fixing** | Fixing before understanding root cause | Complete 5 Whys before writing code |
| **Tunnel Vision** | Only looking at obvious locations | Map upstream/downstream dependencies |
| **Stack Overflow Copy-Paste** | Applying solutions without understanding | Understand WHY the solution works |

### During-Fix Anti-Patterns

| Anti-Pattern | Symptoms | Correct Approach |
|--------------|----------|------------------|
| **Symptom Fixing** | Adding workarounds, null checks without understanding why | Find and fix root cause |
| **Fix Pile-Up** | Multiple unrelated changes in one fix | One fix per root cause |
| **Magic Numbers** | Adding arbitrary delays, retries without analysis | Understand timing/resource issue |
| **Commented Code** | Leaving "backup" code commented out | Use version control, delete cleanly |

### Post-Fix Anti-Patterns

| Anti-Pattern | Symptoms | Correct Approach |
|--------------|----------|------------------|
| **Fix Without Verify** | Declaring "fixed" without running tests | Always run P1 tests minimum |
| **Blind AI Trust** | Accepting AI suggestions without testing | Verify fix addresses the failing scenario |
| **Full Regression Compulsion** | Running 4000+ tests for every fix | Use tiered validation (P1/P2/P3) |
| **Silent Merge** | Merging without review for "simple" fixes | All fixes need verification |

### Investigation Anti-Patterns

| Anti-Pattern | Symptoms | Correct Approach |
|--------------|----------|------------------|
| **Circular Investigation** | Testing same hypotheses repeatedly | Document debug journey |
| **Heisenberg Debugging** | Adding debug code that changes behavior | Use non-invasive logging |
| **Blame Game** | Assuming it's someone else's code/library | Verify assumptions with tests |
| **Environment Blame** | "Works on my machine" | Test in consistent environment |

---

## Detailed Anti-Pattern Analysis

### Shotgun Debugging

**Description**: Making random changes hoping the bug will disappear.

**Example**:
```typescript
// BAD: Random changes without hypothesis
function login(user) {
  // Try adding timeout?
  await sleep(100);
  // Maybe add null check?
  if (user == null) return;
  // What if we try-catch?
  try {
    return doLogin(user);
  } catch (e) {
    // Maybe retry?
    return doLogin(user);
  }
}
```

**Why It's Bad**:
- Wastes time on irrelevant changes
- May mask the real bug without fixing it
- Makes code harder to maintain
- No understanding = bug will recur

**Correct Approach**:
1. Observe: What exactly fails?
2. Hypothesize: "The null user case isn't handled"
3. Experiment: Add logging to confirm user is null
4. Fix: Handle the specific case
5. Verify: Test the scenario that was failing

---

### Fix Without Verify

**Description**: Declaring a fix complete without running tests or verifying the scenario.

**Example Conversation**:
```
Developer: "I fixed the login bug, the null check was missing"
Reviewer: "Did you test it?"
Developer: "The code looks right, it should work"
```

**Why It's Bad**:
- "Should work" ≠ "Does work"
- Untested fixes often introduce regressions
- User may still experience the bug
- Erodes trust in "fixed" status

**Correct Approach**:
1. Before fixing: Reproduce the bug
2. After fixing: Verify the scenario that was failing
3. Run P1 tests (direct coverage)
4. Run P2 tests if time allows
5. Document verification in debug report

---

### Symptom Fixing

**Description**: Adding workarounds instead of fixing the root cause.

**Example**:
```typescript
// SYMPTOM: API returns 500 when profile is null

// BAD: Workaround without understanding
function getProfile(user) {
  try {
    return fetchProfile(user);
  } catch (e) {
    return {}; // Just return empty, "fixes" the 500
  }
}

// GOOD: Fix root cause
function getProfile(user) {
  if (!user.hasProfile) {
    return createDefaultProfile(user);  // Handle the actual case
  }
  return fetchProfile(user);
}
```

**Why It's Bad**:
- Bug still exists, just hidden
- Data inconsistency downstream
- Users may see incorrect behavior
- Future bugs harder to diagnose

**Correct Approach**:
1. Use 5 Whys to find root cause
2. Fix at the appropriate level
3. Consider: Why was the symptom happening?
4. Add proper handling, not just suppression

---

### Full Regression Compulsion

**Description**: Running all 4000+ tests after every small fix.

**Why It's Bad**:
- Wastes CI resources
- Slows down development
- Creates analysis paralysis
- Often triggered by fear, not necessity

**When Full Regression IS Appropriate**:
- Before major release
- After architecture changes
- When risk scope is "broad"
- When confidence is "low"

**Correct Approach**:
Use tiered validation:
- P1 tests: Always run (direct coverage)
- P2 tests: Run for medium+ complexity
- P3 tests: Run for high complexity or broad scope

---

### Circular Investigation

**Description**: Testing the same hypotheses multiple times without documenting.

**Example Timeline**:
```
10:00 - "Maybe it's a timing issue" - added delay, didn't help
10:30 - "Let me check the database" - queries look fine
11:00 - "What if it's timing?" - added delay again (forgot)
11:30 - "Database seems slow" - checked queries again
```

**Why It's Bad**:
- Wastes time on already-ruled-out theories
- Context lost between attempts
- Frustration increases, efficiency drops
- No learning accumulates

**Correct Approach**:
Document debug journey:
```yaml
hypotheses_tested:
  - hypothesis: "Timing issue"
    result: rejected
    evidence: "Delays don't fix it"
  - hypothesis: "Database slow"
    result: rejected
    evidence: "Query logs show <10ms"
```

---

## Quick Reference: What to Do Instead

| Instead of... | Do This |
|---------------|---------|
| Random changes | Form and test hypotheses |
| Declaring "fixed" | Verify with P1 tests |
| Workarounds | Find and fix root cause |
| Full regression every time | Use tiered validation |
| Forgetting investigations | Document debug journey |
| Copying solutions | Understand why they work |
| Assuming library bugs | Verify with isolated test |
| "Works on my machine" | Test in CI environment |

---

## Red Flags During Code Review

When reviewing a fix, watch for these indicators of anti-patterns:

1. **No tests changed/added** - Fix may not be verified
2. **Generic try-catch added** - May be symptom fixing
3. **Magic numbers or delays** - May be shotgun debugging
4. **"Cleanup" mixed with fix** - May obscure actual fix
5. **No explanation of root cause** - May not understand issue
6. **"This should work"** - Not verified

---

## Self-Check Before Declaring Fixed

- [ ] Can I explain the root cause in one sentence?
- [ ] Did I verify the scenario that was failing?
- [ ] Did I run P1 tests (direct coverage)?
- [ ] Is this fix addressing root cause, not just symptoms?
- [ ] Did I document my investigation (if medium/high complexity)?
- [ ] Would I bet $100 this is actually fixed?
