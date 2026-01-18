# Test Audit Fixtures

Test fixtures for validating P0.6-8 Test Audit skills.

## Fixtures Overview

| Fixture | File | Expected Violations | Test Effectiveness |
|---------|------|---------------------|-------------------|
| Clean | `clean/calculator.test.ts` | None | 100% |
| T1 Violation | `t1-violation/proxy.test.ts` | T1 (mock spawn) | ~20% |
| T2 Violation | `t2-violation/db.test.ts` | T2 (call-only assertions) | ~92% |
| T3 Violation | `t3-violation/api.integration.ts` | T3 (mock fetch in integration) | ~15% |
| T3+ Violation | `t3plus-violation/workflow.integration.ts` | T3+ (broken chain) | ~30% |
| Mixed Types | `mixed-types/everything.test.ts` | test_management risk | N/A |

## Expected P0.6 Classification

```yaml
files:
  - path: clean/calculator.test.ts
    category: unit
    needs_deep_analysis: false

  - path: t1-violation/proxy.test.ts
    category: unit
    needs_deep_analysis: true
    deep_analysis_reason: "Unit test mocks core module (spawn)"

  - path: t2-violation/db.test.ts
    category: unit
    needs_deep_analysis: true
    deep_analysis_reason: "Unit test with >3 top-level mocks"

  - path: t3-violation/api.integration.ts
    category: integration
    needs_deep_analysis: true
    deep_analysis_reason: "Integration test contains mocks"

  - path: t3plus-violation/workflow.integration.ts
    category: integration
    needs_deep_analysis: true
    deep_analysis_reason: "Integration test contains mocks"

  - path: mixed-types/everything.test.ts
    category: unit
    needs_deep_analysis: true
    risk: test_management
```

## Expected P0.7 Violations

### T1: Mocking System Under Test
- **File**: `t1-violation/proxy.test.ts`
- **Line**: 15
- **Pattern**: `jest.spyOn(child_process, 'spawn')`
- **Scope**: Lines 15-55 (all tests depend on mock)
- **Priority**: P0 (false confidence)

### T2: Verifying Calls Not Results
- **File**: `t2-violation/db.test.ts`
- **Lines**: 42, 56, 70
- **Pattern**: `expect(mockDb.save).toHaveBeenCalled()`
- **Scope**: Single lines
- **Priority**: P1 (incomplete verification)

### T3: Mock at Integration Boundary
- **File**: `t3-violation/api.integration.ts`
- **Line**: 8
- **Pattern**: `jest.mock('node-fetch')`
- **Scope**: Lines 8-65
- **Priority**: P1 (defeats integration purpose)

### T3+: Broken Integration Chain
- **File**: `t3plus-violation/workflow.integration.ts`
- **Lines**: 45, 62, 78
- **Pattern**: Mock data used instead of real function output
- **Scope**: Lines 45-85
- **Priority**: P0 (false confidence)

## Expected P0.8 Directive

```yaml
directive:
  REWRITE_REQUIRED: true
  gate_triggered: "Gate 1: Impact (P0 violations exist)"
  files_to_rewrite:
    - path: t1-violation/proxy.test.ts
      priority: P0
    - path: t3plus-violation/workflow.integration.ts
      priority: P0
    - path: t3-violation/api.integration.ts
      priority: P1
  files_advisory:
    - path: t2-violation/db.test.ts
      priority: P1
      reason: "Above 95% threshold"
```

## Usage

Run test audit on fixtures:
```bash
/test-audit tests/fixtures/test-audit/
```

Expected outcome:
1. P0.6 classifies all 6 files, flags 5 for deep analysis
2. P0.7 finds violations in 4 files
3. P0.8 triggers REWRITE_REQUIRED via Gate 1 (P0 violations)
