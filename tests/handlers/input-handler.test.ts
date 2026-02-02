import { validateUserInput, processUserQuery, formatDisplayName } from '../../scripts/handlers/input-handler';

describe('validateUserInput', () => {
  it('should validate a correct user input', () => {
    const input = {
      username: 'johndoe',
      email: 'john@example.com',
      age: 25,
      preferences: ['dark-mode', 'notifications'],
    };

    const result = validateUserInput(input);

    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
    expect(result.sanitized).toBeDefined();
    expect(result.sanitized?.username).toBe('johndoe');
  });

  it('should reject input without username', () => {
    const input = {
      email: 'john@example.com',
      age: 25,
      preferences: [],
    };

    const result = validateUserInput(input);

    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Username must be a string');
  });

  it('should reject short usernames', () => {
    const input = {
      username: 'ab',
      email: 'john@example.com',
      age: 25,
      preferences: [],
    };

    const result = validateUserInput(input);

    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Username must be at least 3 characters');
  });

  it('should reject invalid email', () => {
    const input = {
      username: 'johndoe',
      email: 'invalid-email',
      age: 25,
      preferences: [],
    };

    const result = validateUserInput(input);

    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Email must contain @');
  });

  it('should reject non-object input', () => {
    const result = validateUserInput('not an object');

    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Input must be an object');
  });

  it('should reject null input', () => {
    const result = validateUserInput(null);

    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Input must be an object');
  });
});

describe('processUserQuery', () => {
  it('should split query into terms', () => {
    const result = processUserQuery('hello world test');

    expect(result).toEqual(['hello', 'world', 'test']);
  });

  it('should handle multiple spaces', () => {
    const result = processUserQuery('hello   world');

    expect(result).toEqual(['hello', 'world']);
  });

  it('should lowercase terms', () => {
    const result = processUserQuery('Hello World');

    expect(result).toEqual(['hello', 'world']);
  });
});

describe('formatDisplayName', () => {
  it('should format first and last name', () => {
    const result = formatDisplayName('John', 'Doe');

    expect(result).toBe('John Doe');
  });

  it('should trim whitespace', () => {
    const result = formatDisplayName('  John  ', '  Doe  ');

    expect(result).toBe('John    Doe');
  });
});
