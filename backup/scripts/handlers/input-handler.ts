interface UserInput {
  username: string;
  email: string;
  age: number;
  preferences: string[];
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
  sanitized?: UserInput;
}

export function validateUserInput(input: unknown): ValidationResult {
  const errors: string[] = [];

  if (!input || typeof input !== 'object') {
    return { valid: false, errors: ['Input must be an object'] };
  }

  const data = input as Record<string, unknown>;

  // Username validation
  if (typeof data.username !== 'string') {
    errors.push('Username must be a string');
  } else if (data.username.length < 3) {
    errors.push('Username must be at least 3 characters');
  } else if (data.username.length > 50) {
    errors.push('Username must be at most 50 characters');
  }

  // Email validation
  if (typeof data.email !== 'string') {
    errors.push('Email must be a string');
  } else if (!data.email.includes('@')) {
    errors.push('Email must contain @');
  }

  // Age validation
  if (typeof data.age !== 'number') {
    errors.push('Age must be a number');
  } else if (data.age < 0 || data.age > 150) {
    errors.push('Age must be between 0 and 150');
  }

  // Preferences validation
  if (!Array.isArray(data.preferences)) {
    errors.push('Preferences must be an array');
  }

  if (errors.length > 0) {
    return { valid: false, errors };
  }

  return {
    valid: true,
    errors: [],
    sanitized: {
      username: String(data.username).trim(),
      email: String(data.email).toLowerCase().trim(),
      age: Number(data.age),
      preferences: (data.preferences as string[]).map(p => String(p).trim()),
    },
  };
}

export function processUserQuery(query: string): string[] {
  const terms = query.split(/\s+/).filter(term => term.length > 0);
  return terms.map(term => term.toLowerCase());
}

export function formatDisplayName(firstName: string, lastName: string): string {
  return `${firstName} ${lastName}`.trim();
}
