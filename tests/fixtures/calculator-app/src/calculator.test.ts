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
  // ==========================================================================
  // Basic Operations
  // ==========================================================================

  // REAL: Verifies subtraction of two positive numbers
  it('should subtract two positive numbers', () => {
    expect(subtract(10, 3)).toBe(7);
  });

  // REAL: Verifies subtraction resulting in negative
  it('should return negative when second number is larger', () => {
    expect(subtract(3, 10)).toBe(-7);
  });

  // REAL: Verifies subtraction of negative numbers
  it('should subtract two negative numbers', () => {
    expect(subtract(-5, -3)).toBe(-2);
  });

  // REAL: Verifies mixed sign subtraction
  it('should subtract negative from positive', () => {
    expect(subtract(5, -3)).toBe(8);
  });

  // REAL: Verifies subtracting positive from negative
  it('should subtract positive from negative', () => {
    expect(subtract(-5, 3)).toBe(-8);
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================

  // REAL: Verifies subtraction with zero
  it('should return the same number when subtracting zero', () => {
    expect(subtract(5, 0)).toBe(5);
  });

  // REAL: Verifies subtracting from zero
  it('should return negated number when subtracting from zero', () => {
    expect(subtract(0, 5)).toBe(-5);
  });

  // REAL: Verifies zero minus zero
  it('should return zero when subtracting zero from zero', () => {
    expect(subtract(0, 0)).toBe(0);
  });

  // REAL: Verifies decimal subtraction
  it('should handle decimal numbers', () => {
    expect(subtract(5.5, 2.2)).toBeCloseTo(3.3);
  });

  // REAL: Verifies very small decimal subtraction
  it('should handle very small decimals', () => {
    expect(subtract(0.1, 0.1)).toBeCloseTo(0);
  });

  // REAL: Verifies same number subtraction
  it('should return zero when subtracting a number from itself', () => {
    expect(subtract(42, 42)).toBe(0);
  });

  // ==========================================================================
  // Input Validation - Type Errors
  // ==========================================================================

  // REAL: Verifies error on string input for first argument
  it('should throw error when first argument is a string', () => {
    expect(() => subtract('5' as any, 3)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on string input for second argument
  it('should throw error when second argument is a string', () => {
    expect(() => subtract(5, '3' as any)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on null input
  it('should throw error when input is null', () => {
    expect(() => subtract(null as any, 3)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on undefined input
  it('should throw error when input is undefined', () => {
    expect(() => subtract(undefined as any, 3)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on object input
  it('should throw error when input is an object', () => {
    expect(() => subtract({} as any, 3)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on array input
  it('should throw error when input is an array', () => {
    expect(() => subtract([1, 2] as any, 3)).toThrow('Invalid input: both arguments must be numbers');
  });

  // ==========================================================================
  // Input Validation - NaN
  // ==========================================================================

  // REAL: Verifies error on NaN first argument
  it('should throw error when first argument is NaN', () => {
    expect(() => subtract(NaN, 3)).toThrow('Invalid input: NaN values are not allowed');
  });

  // REAL: Verifies error on NaN second argument
  it('should throw error when second argument is NaN', () => {
    expect(() => subtract(5, NaN)).toThrow('Invalid input: NaN values are not allowed');
  });

  // REAL: Verifies error when both arguments are NaN
  it('should throw error when both arguments are NaN', () => {
    expect(() => subtract(NaN, NaN)).toThrow('Invalid input: NaN values are not allowed');
  });

  // ==========================================================================
  // Input Validation - Infinity
  // ==========================================================================

  // REAL: Verifies error on positive Infinity first argument
  it('should throw error when first argument is Infinity', () => {
    expect(() => subtract(Infinity, 3)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // REAL: Verifies error on negative Infinity first argument
  it('should throw error when first argument is negative Infinity', () => {
    expect(() => subtract(-Infinity, 3)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // REAL: Verifies error on Infinity second argument
  it('should throw error when second argument is Infinity', () => {
    expect(() => subtract(5, Infinity)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // REAL: Verifies error on negative Infinity second argument
  it('should throw error when second argument is negative Infinity', () => {
    expect(() => subtract(5, -Infinity)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // ==========================================================================
  // Boundary Tests - Safe Integer Limits
  // ==========================================================================

  // REAL: Verifies subtraction at MAX_SAFE_INTEGER boundary
  it('should handle subtraction at MAX_SAFE_INTEGER', () => {
    expect(subtract(Number.MAX_SAFE_INTEGER, 1)).toBe(Number.MAX_SAFE_INTEGER - 1);
  });

  // REAL: Verifies subtraction at MIN_SAFE_INTEGER boundary
  it('should handle subtraction at MIN_SAFE_INTEGER', () => {
    expect(subtract(Number.MIN_SAFE_INTEGER, -1)).toBe(Number.MIN_SAFE_INTEGER + 1);
  });

  // REAL: Verifies overflow detection when result exceeds MAX_SAFE_INTEGER
  it('should throw RangeError when result exceeds MAX_SAFE_INTEGER', () => {
    expect(() => subtract(Number.MAX_SAFE_INTEGER, -Number.MAX_SAFE_INTEGER))
      .toThrow(RangeError);
  });

  // REAL: Verifies overflow detection when result is below MIN_SAFE_INTEGER
  it('should throw RangeError when result is below MIN_SAFE_INTEGER', () => {
    expect(() => subtract(-Number.MAX_SAFE_INTEGER, Number.MAX_SAFE_INTEGER))
      .toThrow(RangeError);
  });

  // REAL: Verifies the error message includes overflow details
  it('should include overflow details in error message', () => {
    expect(() => subtract(Number.MAX_SAFE_INTEGER, -Number.MAX_SAFE_INTEGER))
      .toThrow(/Overflow detected/);
  });

  // ==========================================================================
  // Large Number Handling
  // ==========================================================================

  // REAL: Verifies handling of large but safe numbers
  it('should handle large numbers within safe bounds', () => {
    const largeNum = 1e10;
    expect(subtract(largeNum, 1e9)).toBe(9e9);
  });

  // REAL: Verifies handling of very small (negative large) numbers
  it('should handle very small negative numbers within safe bounds', () => {
    const smallNum = -1e10;
    expect(subtract(smallNum, -1e9)).toBe(-9e9);
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

describe('divide - REAL TESTS', () => {
  // ==========================================================================
  // Basic Operations
  // ==========================================================================

  // REAL: Verifies division of two positive numbers
  it('should divide two positive numbers', () => {
    expect(divide(10, 2)).toBe(5);
  });

  // REAL: Verifies division resulting in decimal
  it('should return decimal when result is not whole', () => {
    expect(divide(7, 2)).toBe(3.5);
  });

  // REAL: Verifies division of negative numbers
  it('should divide two negative numbers', () => {
    expect(divide(-12, -4)).toBe(3);
  });

  // REAL: Verifies mixed sign division
  it('should divide positive by negative', () => {
    expect(divide(12, -4)).toBe(-3);
  });

  // REAL: Verifies division of negative by positive
  it('should divide negative by positive', () => {
    expect(divide(-12, 4)).toBe(-3);
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================

  // REAL: Verifies zero dividend
  it('should return zero when dividing zero by non-zero', () => {
    expect(divide(0, 5)).toBe(0);
  });

  // REAL: Verifies decimal division
  it('should handle decimal numbers', () => {
    expect(divide(5.5, 2.2)).toBeCloseTo(2.5);
  });

  // REAL: Verifies very small decimal division
  it('should handle very small decimals', () => {
    expect(divide(0.1, 0.1)).toBeCloseTo(1);
  });

  // REAL: Verifies same number division
  it('should return one when dividing a number by itself', () => {
    expect(divide(42, 42)).toBe(1);
  });

  // ==========================================================================
  // Division by Zero
  // ==========================================================================

  // REAL: Verifies error on division by zero
  it('should throw error when dividing by zero', () => {
    expect(() => divide(10, 0)).toThrow('Division by zero: cannot divide by zero');
  });

  // REAL: Verifies error on zero divided by zero
  it('should throw error when dividing zero by zero', () => {
    expect(() => divide(0, 0)).toThrow('Division by zero: cannot divide by zero');
  });

  // REAL: Verifies error on negative number divided by zero
  it('should throw error when dividing negative by zero', () => {
    expect(() => divide(-5, 0)).toThrow('Division by zero: cannot divide by zero');
  });

  // ==========================================================================
  // Input Validation - Type Errors
  // ==========================================================================

  // REAL: Verifies error on string input for first argument
  it('should throw error when first argument is a string', () => {
    expect(() => divide('10' as any, 2)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on string input for second argument
  it('should throw error when second argument is a string', () => {
    expect(() => divide(10, '2' as any)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on null input
  it('should throw error when input is null', () => {
    expect(() => divide(null as any, 2)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on undefined input
  it('should throw error when input is undefined', () => {
    expect(() => divide(undefined as any, 2)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on object input
  it('should throw error when input is an object', () => {
    expect(() => divide({} as any, 2)).toThrow('Invalid input: both arguments must be numbers');
  });

  // REAL: Verifies error on array input
  it('should throw error when input is an array', () => {
    expect(() => divide([10] as any, 2)).toThrow('Invalid input: both arguments must be numbers');
  });

  // ==========================================================================
  // Input Validation - NaN
  // ==========================================================================

  // REAL: Verifies error on NaN first argument
  it('should throw error when first argument is NaN', () => {
    expect(() => divide(NaN, 2)).toThrow('Invalid input: NaN values are not allowed');
  });

  // REAL: Verifies error on NaN second argument
  it('should throw error when second argument is NaN', () => {
    expect(() => divide(10, NaN)).toThrow('Invalid input: NaN values are not allowed');
  });

  // REAL: Verifies error when both arguments are NaN
  it('should throw error when both arguments are NaN', () => {
    expect(() => divide(NaN, NaN)).toThrow('Invalid input: NaN values are not allowed');
  });

  // ==========================================================================
  // Input Validation - Infinity
  // ==========================================================================

  // REAL: Verifies error on positive Infinity first argument
  it('should throw error when first argument is Infinity', () => {
    expect(() => divide(Infinity, 2)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // REAL: Verifies error on negative Infinity first argument
  it('should throw error when first argument is negative Infinity', () => {
    expect(() => divide(-Infinity, 2)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // REAL: Verifies error on Infinity second argument
  it('should throw error when second argument is Infinity', () => {
    expect(() => divide(10, Infinity)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // REAL: Verifies error on negative Infinity second argument
  it('should throw error when second argument is negative Infinity', () => {
    expect(() => divide(10, -Infinity)).toThrow('Invalid input: Infinity values are not allowed');
  });

  // ==========================================================================
  // Boundary Tests - Safe Integer Limits
  // ==========================================================================

  // REAL: Verifies division at MAX_SAFE_INTEGER boundary
  it('should handle division at MAX_SAFE_INTEGER', () => {
    expect(divide(Number.MAX_SAFE_INTEGER, 1)).toBe(Number.MAX_SAFE_INTEGER);
  });

  // REAL: Verifies division at MIN_SAFE_INTEGER boundary
  it('should handle division at MIN_SAFE_INTEGER', () => {
    expect(divide(Number.MIN_SAFE_INTEGER, 1)).toBe(Number.MIN_SAFE_INTEGER);
  });

  // REAL: Verifies division resulting in value within safe bounds
  it('should handle division that results in safe integer', () => {
    expect(divide(Number.MAX_SAFE_INTEGER, Number.MAX_SAFE_INTEGER)).toBe(1);
  });

  // ==========================================================================
  // Large Number Handling
  // ==========================================================================

  // REAL: Verifies handling of large but safe numbers
  it('should handle large numbers within safe bounds', () => {
    const largeNum = 1e10;
    expect(divide(largeNum, 1e5)).toBe(1e5);
  });

  // REAL: Verifies handling of very small (negative large) numbers
  it('should handle very small negative numbers within safe bounds', () => {
    const smallNum = -1e10;
    expect(divide(smallNum, -1e5)).toBe(1e5);
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

// =============================================================================
// P0.4 VERIFICATION TESTS - These will FAIL due to intentional bugs
// =============================================================================

import { percentage, safeDivide, safeMultiply, safeAdd } from './calculator';

describe('P0.4 Verification - Small Bug (off-by-one)', () => {
  // P1 PRIORITY: Direct unit test - will FAIL due to off-by-one bug in add()
  it('should add 2 + 2 = 4', () => {
    expect(add(2, 2)).toBe(4);  // FAILS: returns 5 due to bug
  });

  it('should add 0 + 0 = 0', () => {
    expect(add(0, 0)).toBe(0);  // FAILS: returns 1 due to bug
  });
});

describe('P0.4 Verification - Medium Bug (null handling)', () => {
  // P1 PRIORITY: Direct test of percentage function
  it('should calculate percentage correctly', () => {
    expect(percentage(25, 100)).toBe(25);  // PASSES (no null)
  });

  it('should handle null value gracefully', () => {
    // FAILS: Returns NaN instead of throwing error
    expect(() => percentage(null as any, 100)).toThrow();
  });

  // P2 PRIORITY: Integration test - Calculator chaining
  it('should get last result doubled after operation', () => {
    const calc = new Calculator();
    calc.add(5, 5);
    expect(calc.getLastResultDoubled()).toBe(20);  // PASSES after add
  });

  it('should handle getLastResultDoubled before any operation', () => {
    const calc = new Calculator();
    // FAILS: Throws because lastResult is null, no graceful handling
    expect(() => calc.getLastResultDoubled()).toThrow();
  });
});

describe('P0.4 Verification - Large Bug (inverted validation)', () => {
  // P1 PRIORITY: Direct tests - ALL FAIL due to inverted validateNumber()
  it('should safely divide valid numbers', () => {
    expect(safeDivide(10, 2)).toBe(5);  // FAILS: throws "Invalid number" for valid input
  });

  it('should safely multiply valid numbers', () => {
    expect(safeMultiply(3, 4)).toBe(12);  // FAILS: throws "Invalid number"
  });

  it('should safely add valid numbers', () => {
    expect(safeAdd(1, 2)).toBe(3);  // FAILS: throws "Invalid number"
  });

  // P2 PRIORITY: Integration - chained operations
  it('should chain safe operations', () => {
    const a = safeAdd(1, 2);
    const b = safeMultiply(a, 3);
    const c = safeDivide(b, 3);
    expect(c).toBe(3);  // FAILS: first operation throws
  });

  // These SHOULD throw but WON'T due to inverted logic
  it('should reject NaN in safeDivide', () => {
    expect(() => safeDivide(NaN, 2)).toThrow();  // FAILS: doesn't throw for NaN
  });

  it('should reject Infinity in safeMultiply', () => {
    expect(() => safeMultiply(Infinity, 2)).toThrow();  // FAILS: doesn't throw
  });
});
