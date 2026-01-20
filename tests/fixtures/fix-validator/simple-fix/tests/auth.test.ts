import { AuthService, UserProfile } from '../src/auth';

describe('AuthService', () => {
  let authService: AuthService;

  beforeEach(() => {
    authService = new AuthService();
  });

  describe('register', () => {
    it('should register a new user', async () => {
      const result = await authService.register('test@example.com', 'password123');

      expect(result.success).toBe(true);
      expect(result.user).toBeDefined();
      expect(result.user?.email).toBe('test@example.com');
    });

    it('should reject empty email', async () => {
      const result = await authService.register('', 'password123');

      expect(result.success).toBe(false);
      expect(result.error).toBe('Email and password required');
    });

    it('should reject duplicate registration', async () => {
      await authService.register('test@example.com', 'password123');
      const result = await authService.register('test@example.com', 'different');

      expect(result.success).toBe(false);
      expect(result.error).toBe('User already exists');
    });
  });

  describe('login', () => {
    beforeEach(async () => {
      await authService.register('user@example.com', 'password123');
      await authService.updateProfile('user@example.com', {
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.png',
        preferences: {
          theme: 'dark',
          notifications: true,
        },
      });
    });

    it('should login existing user with welcome message', async () => {
      const result = await authService.login('user@example.com', 'password123');

      expect(result.success).toBe(true);
      expect(result.user).toBeDefined();
      expect(result.welcomeMessage).toContain('Test User');
    });

    it('should reject invalid credentials', async () => {
      const result = await authService.login('nonexistent@example.com', 'password');

      expect(result.success).toBe(false);
      expect(result.error).toBe('Invalid credentials');
    });
  });

  describe('login without profile', () => {
    it('should login new user without profile and provide welcome message', async () => {
      await authService.register('newuser@example.com', 'password123');

      const result = await authService.login('newuser@example.com', 'password123');

      expect(result.success).toBe(true);
      expect(result.user).toBeDefined();
      expect(result.welcomeMessage).toBeDefined();
      expect(result.welcomeMessage).toMatch(/Good (morning|afternoon|evening), there!/);
    });
  });

  describe('updateProfile', () => {
    it('should update user profile', async () => {
      await authService.register('profile@example.com', 'password123');

      const profile: UserProfile = {
        displayName: 'Updated Name',
        avatarUrl: 'https://example.com/new-avatar.png',
        preferences: {
          theme: 'light',
          notifications: false,
        },
      };

      const result = await authService.updateProfile('profile@example.com', profile);

      expect(result.success).toBe(true);
      expect(result.user?.profile?.displayName).toBe('Updated Name');
    });

    it('should reject update for nonexistent user', async () => {
      const result = await authService.updateProfile('nobody@example.com', {
        displayName: 'Nobody',
        avatarUrl: '',
        preferences: { theme: 'dark', notifications: false },
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('User not found');
    });
  });
});
