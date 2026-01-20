import { Calculator } from '../src/calculator';

describe('Calculator', () => {
  let calculator: Calculator;

  beforeEach(() => {
    calculator = new Calculator();
  });

  describe('divide', () => {
    it('should return error when dividing by zero', () => {
      const result = calculator.divide(10, 0);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Cannot divide by zero');
      expect(result.value).toBeUndefined();
    });

    it('should divide positive numbers correctly', () => {
      const result = calculator.divide(10, 2);

      expect(result.success).toBe(true);
      expect(result.value).toBe(5);
    });

    it('should divide negative numbers correctly', () => {
      const result = calculator.divide(-10, 2);

      expect(result.success).toBe(true);
      expect(result.value).toBe(-5);
    });

    it('should respect precision setting', () => {
      const calc = new Calculator(2);
      const result = calc.divide(1, 3);

      expect(result.success).toBe(true);
      expect(result.value).toBe(0.33);
    });

    it('should handle zero dividend correctly', () => {
      const result = calculator.divide(0, 5);

      expect(result.success).toBe(true);
      expect(result.value).toBe(0);
    });
  });

  describe('add', () => {
    it('should add two numbers correctly', () => {
      const result = calculator.add(2, 3);

      expect(result.success).toBe(true);
      expect(result.value).toBe(5);
    });
  });

  describe('subtract', () => {
    it('should subtract two numbers correctly', () => {
      const result = calculator.subtract(5, 3);

      expect(result.success).toBe(true);
      expect(result.value).toBe(2);
    });
  });

  describe('multiply', () => {
    it('should multiply two numbers correctly', () => {
      const result = calculator.multiply(4, 3);

      expect(result.success).toBe(true);
      expect(result.value).toBe(12);
    });
  });

  describe('percentage', () => {
    it('should calculate percentage correctly', () => {
      const result = calculator.percentage(200, 15);

      expect(result.success).toBe(true);
      expect(result.value).toBe(30);
    });
  });

  describe('average', () => {
    it('should calculate average correctly', () => {
      const result = calculator.average([10, 20, 30]);

      expect(result.success).toBe(true);
      expect(result.value).toBe(20);
    });

    it('should return error for empty array', () => {
      const result = calculator.average([]);

      expect(result.success).toBe(false);
      expect(result.error).toBe('Cannot calculate average of empty array');
    });
  });
});
