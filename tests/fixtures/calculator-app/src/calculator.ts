/**
 * Calculator - Test Fixture for Bulwark Skills Validation
 *
 * This file contains INTENTIONAL issues for testing:
 * - Bugs: Division by zero not handled, overflow issues
 * - Security: eval() usage, no input sanitization
 * - Type issues: any usage, unsafe assertions
 *
 * DO NOT FIX THESE ISSUES - they are for testing purposes.
 */

// TYPE ISSUE: Using 'any' instead of proper types
export function calculate(expression: any): any {
  // SECURITY ISSUE: Using eval() - vulnerable to code injection
  return eval(expression);
}

/**
 * Divides the first number by the second with comprehensive validation.
 *
 * This function performs safe division with the following checks:
 * - Type validation: ensures both inputs are numbers
 * - NaN detection: rejects NaN values
 * - Infinity handling: rejects infinite values as inputs
 * - Division by zero: throws error instead of returning Infinity
 * - Overflow detection: checks if the result exceeds safe integer bounds
 *
 * @param a - The dividend (number to be divided)
 * @param b - The divisor (number to divide by)
 * @returns The quotient of a divided by b
 * @throws {Error} If inputs are not valid numbers
 * @throws {Error} If inputs are NaN or Infinity
 * @throws {Error} If attempting to divide by zero
 * @throws {RangeError} If the result would overflow safe integer bounds
 *
 * @example
 * divide(10, 2);   // Returns 5
 * divide(-12, 4);  // Returns -3
 * divide(7, 2);    // Returns 3.5
 */
export function divide(a: number, b: number): number {
  // Input type validation - ensure both arguments are numbers
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: both arguments must be numbers');
  }

  // NaN validation - reject NaN values which propagate silently
  if (Number.isNaN(a) || Number.isNaN(b)) {
    throw new Error('Invalid input: NaN values are not allowed');
  }

  // Infinity validation - reject infinite values
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    throw new Error('Invalid input: Infinity values are not allowed');
  }

  // Division by zero validation
  if (b === 0) {
    throw new Error('Division by zero: cannot divide by zero');
  }

  // Perform the division
  const result = a / b;

  // Check if the result became infinite (overflow to Infinity)
  if (!Number.isFinite(result)) {
    throw new RangeError('Overflow detected: result exceeds maximum representable value');
  }

  // Overflow detection - check if result exceeds safe integer bounds
  // Note: Division typically doesn't overflow, but we check for consistency
  if (result > Number.MAX_SAFE_INTEGER || result < Number.MIN_SAFE_INTEGER) {
    throw new RangeError(
      `Overflow detected: result ${result} exceeds safe integer bounds`
    );
  }

  return result;
}

/**
 * Multiplies two numbers with comprehensive validation and overflow protection.
 *
 * This function performs safe multiplication with the following checks:
 * - Type validation: ensures both inputs are numbers
 * - NaN detection: rejects NaN values
 * - Infinity handling: rejects infinite values as inputs
 * - Overflow detection: checks if the result exceeds safe integer bounds or becomes infinite
 *
 * @param a - The multiplicand (first factor)
 * @param b - The multiplier (second factor)
 * @returns The product of a and b
 * @throws {Error} If inputs are not valid numbers
 * @throws {Error} If inputs are NaN or Infinity
 * @throws {RangeError} If the result would overflow safe integer bounds
 *
 * @example
 * multiply(6, 7);   // Returns 42
 * multiply(-3, 4);  // Returns -12
 * multiply(0, 100); // Returns 0
 */
export function multiply(a: number, b: number): number {
  // Input type validation - ensure both arguments are numbers
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: both arguments must be numbers');
  }

  // NaN validation - reject NaN values which propagate silently
  if (Number.isNaN(a) || Number.isNaN(b)) {
    throw new Error('Invalid input: NaN values are not allowed');
  }

  // Infinity validation - reject infinite values
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    throw new Error('Invalid input: Infinity values are not allowed');
  }

  // Perform the multiplication
  const result = a * b;

  // Check if the result became infinite (overflow to Infinity)
  // This happens before safe integer bounds are exceeded for large floats
  if (!Number.isFinite(result)) {
    throw new RangeError('Overflow detected: result exceeds maximum representable value');
  }

  // Overflow detection - check if result exceeds safe integer bounds
  // This catches cases where the result would lose precision
  if (result > Number.MAX_SAFE_INTEGER || result < Number.MIN_SAFE_INTEGER) {
    throw new RangeError(
      `Overflow detected: result ${result} exceeds safe integer bounds`
    );
  }

  return result;
}

// Correct implementation for comparison
// Adds two numbers together after validating both inputs are numbers.
// Throws an error if either input is not a number.
export function add(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: numbers required');
  }
  return a + b;
}

/**
 * Subtracts the second number from the first with comprehensive validation.
 *
 * This function performs safe subtraction with the following checks:
 * - Type validation: ensures both inputs are numbers
 * - NaN detection: rejects NaN values
 * - Infinity handling: rejects infinite values as inputs
 * - Overflow detection: checks if the result exceeds safe integer bounds
 *
 * @param a - The minuend (number to subtract from)
 * @param b - The subtrahend (number to subtract)
 * @returns The difference of a minus b
 * @throws {Error} If inputs are not valid numbers
 * @throws {Error} If inputs are NaN or Infinity
 * @throws {RangeError} If the result would overflow safe integer bounds
 *
 * @example
 * subtract(10, 3);  // Returns 7
 * subtract(-5, -3); // Returns -2
 */
export function subtract(a: number, b: number): number {
  // Input type validation - ensure both arguments are numbers
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: both arguments must be numbers');
  }

  // NaN validation - reject NaN values which propagate silently
  if (Number.isNaN(a) || Number.isNaN(b)) {
    throw new Error('Invalid input: NaN values are not allowed');
  }

  // Infinity validation - reject infinite values
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    throw new Error('Invalid input: Infinity values are not allowed');
  }

  // Perform the subtraction
  const result = a - b;

  // Overflow detection - check if result exceeds safe integer bounds
  // This catches cases where the result would lose precision
  if (result > Number.MAX_SAFE_INTEGER || result < Number.MIN_SAFE_INTEGER) {
    throw new RangeError(
      `Overflow detected: result ${result} exceeds safe integer bounds`
    );
  }

  // Check if the result itself became infinite (extreme overflow)
  if (!Number.isFinite(result)) {
    throw new RangeError('Overflow detected: result is not finite');
  }

  return result;
}

/**
 * Computes the modulo (remainder) of dividing the first number by the second.
 *
 * This function performs safe modulo operation with the following checks:
 * - Type validation: ensures both inputs are numbers
 * - NaN detection: rejects NaN values
 * - Infinity handling: rejects infinite values as inputs
 * - Division by zero: throws error when divisor is zero
 * - Result validation: ensures result is a valid finite number
 *
 * Note: JavaScript's % operator returns a remainder with the sign of the dividend.
 * For example: -7 % 3 = -1 (not 2 as in mathematical modulo)
 *
 * @param a - The dividend (number to be divided)
 * @param b - The divisor (number to divide by)
 * @returns The remainder of a divided by b
 * @throws {Error} If inputs are not valid numbers
 * @throws {Error} If inputs are NaN or Infinity
 * @throws {Error} If attempting to compute modulo with zero divisor
 *
 * @example
 * modulo(10, 3);   // Returns 1
 * modulo(-7, 3);   // Returns -1
 * modulo(7.5, 2);  // Returns 1.5
 */
export function modulo(a: number, b: number): number {
  // Input type validation - ensure both arguments are numbers
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: both arguments must be numbers');
  }

  // NaN validation - reject NaN values which propagate silently
  if (Number.isNaN(a) || Number.isNaN(b)) {
    throw new Error('Invalid input: NaN values are not allowed');
  }

  // Infinity validation - reject infinite values
  if (!Number.isFinite(a) || !Number.isFinite(b)) {
    throw new Error('Invalid input: Infinity values are not allowed');
  }

  // Modulo by zero validation - would produce NaN
  if (b === 0) {
    throw new Error('Modulo by zero: cannot compute remainder with zero divisor');
  }

  // Perform the modulo operation
  const result = a % b;

  // Result validation - ensure result is finite
  // This should not happen with valid finite inputs, but guards against edge cases
  if (!Number.isFinite(result)) {
    throw new RangeError('Invalid result: modulo operation produced non-finite value');
  }

  return result;
}

// TYPE ISSUE: Unsafe type assertion
export function parseNumber(input: string): number {
  return input as unknown as number;  // WRONG: doesn't actually parse
}

// SECURITY ISSUE: No input sanitization
export function evaluateFormula(formula: string): number {
  // Vulnerable to injection attacks
  const sanitized = formula;  // No actual sanitization
  return eval(sanitized);
}

// BUG: Race condition in async operation
let sharedState = 0;

export async function incrementAsync(): Promise<number> {
  const current = sharedState;
  await new Promise(resolve => setTimeout(resolve, 10));
  sharedState = current + 1;  // Race condition: doesn't read latest value
  return sharedState;
}

export function resetState(): void {
  sharedState = 0;
}

// Correct async implementation for comparison
export async function incrementAsyncSafe(): Promise<number> {
  sharedState += 1;
  return sharedState;
}

// Memory tracking for testing
export class Calculator {
  private history: number[] = [];

  add(a: number, b: number): number {
    const result = a + b;
    this.history.push(result);
    return result;
  }

  // BUG: Memory leak - history never cleared
  getHistory(): number[] {
    return this.history;
  }

  // Missing: clearHistory() method
}
