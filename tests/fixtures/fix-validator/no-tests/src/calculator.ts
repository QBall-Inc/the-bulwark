export interface CalculationResult {
  success: boolean;
  value?: number;
  error?: string;
}

export class Calculator {
  private precision: number;

  constructor(precision: number = 2) {
    this.precision = precision;
  }

  add(a: number, b: number): CalculationResult {
    const value = this.round(a + b);
    return { success: true, value };
  }

  subtract(a: number, b: number): CalculationResult {
    const value = this.round(a - b);
    return { success: true, value };
  }

  multiply(a: number, b: number): CalculationResult {
    const value = this.round(a * b);
    return { success: true, value };
  }

  divide(a: number, b: number): CalculationResult {
    if (b === 0) {
      return { success: false, error: 'Cannot divide by zero' };
    }

    const value = this.round(a / b);
    return { success: true, value };
  }

  percentage(value: number, percent: number): CalculationResult {
    const result = this.round((value * percent) / 100);
    return { success: true, value: result };
  }

  average(values: number[]): CalculationResult {
    if (values.length === 0) {
      return { success: false, error: 'Cannot calculate average of empty array' };
    }

    const sum = values.reduce((acc, val) => acc + val, 0);
    const avg = this.round(sum / values.length);
    return { success: true, value: avg };
  }

  private round(value: number): number {
    const factor = Math.pow(10, this.precision);
    return Math.round(value * factor) / factor;
  }
}
