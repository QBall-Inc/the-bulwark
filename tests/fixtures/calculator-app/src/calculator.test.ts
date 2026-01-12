/**
 * Calculator Tests - Test Fixture for Bulwark Skills Validation
 *
 * This file contains a MIX of test types for test-audit validation:
 * - REAL tests: Actually verify behavior
 * - MOCK-HEAVY tests: Verify mocks, not real behavior
 *
 * Labels indicate test type for validation purposes.
 */

import { add, subtract, divide, multiply, Calculator } from './calculator';

// =============================================================================
// REAL INTEGRATION TESTS - These verify actual behavior
// =============================================================================

describe('add - REAL TESTS', () => {
  // REAL: Verifies actual output
  it('should add two positive numbers', () => {
    const result = add(2, 3);
    expect(result).toBe(5);
  });

  // REAL: Verifies actual output
  it('should add negative numbers', () => {
    const result = add(-2, -3);
    expect(result).toBe(-5);
  });

  // REAL: Verifies error handling
  it('should throw on invalid input', () => {
    expect(() => add('a' as any, 2)).toThrow('Invalid input');
  });
});

describe('subtract - REAL TESTS', () => {
  // REAL: Verifies actual output
  it('should subtract two numbers', () => {
    expect(subtract(5, 3)).toBe(2);
  });
});

// =============================================================================
// MOCK-HEAVY TESTS - These verify mocks, not behavior
// =============================================================================

describe('Calculator class - MOCK-HEAVY TESTS', () => {
  // MOCK-HEAVY: Mocks the method being tested
  it('should call add method', () => {
    const calc = new Calculator();
    const addSpy = jest.spyOn(calc, 'add');

    calc.add(2, 3);

    // BAD: Verifies the spy was called, not the actual result
    expect(addSpy).toHaveBeenCalledWith(2, 3);
  });

  // MOCK-HEAVY: Mocks return value instead of testing real behavior
  it('should return mocked value', () => {
    const calc = new Calculator();
    jest.spyOn(calc, 'add').mockReturnValue(100);

    const result = calc.add(2, 3);

    // BAD: Tests the mock, not the actual addition
    expect(result).toBe(100);
  });
});

describe('divide - MOCK-HEAVY TESTS', () => {
  // MOCK-HEAVY: Mocks the entire function
  it('should handle division', () => {
    const mockDivide = jest.fn().mockReturnValue(2);

    const result = mockDivide(10, 5);

    // BAD: Tests mock, never calls real divide()
    expect(mockDivide).toHaveBeenCalled();
    expect(result).toBe(2);
  });
});

describe('multiply - MOCK-HEAVY TESTS', () => {
  // MOCK-HEAVY: Uses mock instead of real implementation
  it('should multiply numbers', () => {
    const mockMultiply = jest.fn((a: number, b: number) => a * b);

    mockMultiply(3, 4);

    // BAD: Verifies mock call, not multiply() function
    expect(mockMultiply).toHaveBeenCalledWith(3, 4);
  });
});

// =============================================================================
// MIXED TESTS - Some good, some bad patterns
// =============================================================================

describe('Calculator integration - MIXED', () => {
  // REAL: Tests actual behavior
  it('should track history', () => {
    const calc = new Calculator();
    calc.add(1, 2);
    calc.add(3, 4);

    const history = calc.getHistory();
    expect(history).toEqual([3, 7]);
  });

  // MOCK-HEAVY: Mocks getHistory instead of testing real behavior
  it('should return history - MOCKED', () => {
    const calc = new Calculator();
    jest.spyOn(calc, 'getHistory').mockReturnValue([1, 2, 3]);

    // BAD: Never actually adds anything, just tests mock
    expect(calc.getHistory()).toEqual([1, 2, 3]);
  });
});

// =============================================================================
// MISSING TESTS - Gaps that should be caught by test-audit
// =============================================================================

// No tests for:
// - calculate() function (security risk)
// - evaluateFormula() function (security risk)
// - parseNumber() function (type safety)
// - incrementAsync() function (race condition)
// - divide() with zero (bug)
// - multiply() with large numbers (overflow)
