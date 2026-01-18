/**
 * Fixture: Mixed Test Types - Test Management Risk
 *
 * Expected classification:
 * - category: unit (default from .test.ts)
 * - needs_deep_analysis: true (mixed types detected)
 * - risk: test_management
 * - recommendation: "Split into separate files by test type"
 *
 * This file contains unit, integration, AND e2e tests mixed together.
 * This is a test management anti-pattern that makes it hard to:
 * - Run tests by type (fast unit vs slow integration)
 * - Understand test coverage by category
 * - Maintain appropriate test isolation
 */

import { UserService } from '../../../src/user-service';
import { Database } from '../../../src/database';
import puppeteer from 'puppeteer';

// UNIT TEST - should be in user-service.test.ts
describe('UserService Unit Tests', () => {
  it('should validate email format', () => {
    const userService = new UserService();

    expect(userService.isValidEmail('test@example.com')).toBe(true);
    expect(userService.isValidEmail('invalid')).toBe(false);
  });

  it('should hash password', () => {
    const userService = new UserService();
    const hash = userService.hashPassword('secret123');

    expect(hash).not.toBe('secret123');
    expect(hash.length).toBeGreaterThan(20);
  });
});

// INTEGRATION TEST - should be in user-service.integration.ts
describe('UserService Integration Tests', () => {
  let db: Database;
  let userService: UserService;

  beforeAll(async () => {
    db = new Database('test_db');
    await db.connect();
    userService = new UserService(db);
  });

  afterAll(async () => {
    await db.disconnect();
  });

  it('should create user in database', async () => {
    const user = await userService.createUser({
      email: 'test@example.com',
      password: 'secret123',
    });

    expect(user.id).toBeDefined();

    // Verify in database
    const dbUser = await db.findOne('users', { id: user.id });
    expect(dbUser.email).toBe('test@example.com');
  });

  it('should handle duplicate email', async () => {
    await expect(
      userService.createUser({
        email: 'test@example.com', // Already exists
        password: 'another123',
      })
    ).rejects.toThrow('Email already exists');
  });
});

// E2E TEST - should be in user-registration.e2e.ts
describe('User Registration E2E', () => {
  let browser: puppeteer.Browser;
  let page: puppeteer.Page;

  beforeAll(async () => {
    browser = await puppeteer.launch();
    page = await browser.newPage();
  });

  afterAll(async () => {
    await browser.close();
  });

  it('should register new user through UI', async () => {
    await page.goto('http://localhost:3000/register');

    await page.type('#email', 'newuser@example.com');
    await page.type('#password', 'securepass123');
    await page.click('#submit');

    await page.waitForSelector('.success-message');
    const message = await page.$eval('.success-message', el => el.textContent);

    expect(message).toContain('Registration successful');
  });

  it('should show validation errors', async () => {
    await page.goto('http://localhost:3000/register');

    await page.type('#email', 'invalid-email');
    await page.click('#submit');

    await page.waitForSelector('.error-message');
    const error = await page.$eval('.error-message', el => el.textContent);

    expect(error).toContain('Invalid email format');
  });
});
