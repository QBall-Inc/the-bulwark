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

// BUG: Division by zero not handled
export function divide(a: number, b: number): number {
  return a / b;  // Returns Infinity instead of throwing error
}

// BUG: Integer overflow not handled
export function multiply(a: number, b: number): number {
  return a * b;  // Can overflow for large numbers
}

// Correct implementation for comparison
export function add(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: numbers required');
  }
  return a + b;
}

export function subtract(a: number, b: number): number {
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Invalid input: numbers required');
  }
  return a - b;
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
