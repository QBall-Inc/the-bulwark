export interface UserProfile {
  displayName: string;
  avatarUrl: string;
  preferences: {
    theme: 'light' | 'dark';
    notifications: boolean;
  };
}

export interface User {
  id: string;
  email: string;
  profile?: UserProfile;
  createdAt: Date;
}

export interface AuthResult {
  success: boolean;
  user?: User;
  error?: string;
  welcomeMessage?: string;
}

export class AuthService {
  private users: Map<string, User> = new Map();

  async register(email: string, password: string): Promise<AuthResult> {
    if (!email || !password) {
      return { success: false, error: 'Email and password required' };
    }

    if (this.users.has(email)) {
      return { success: false, error: 'User already exists' };
    }

    const user: User = {
      id: crypto.randomUUID(),
      email,
      createdAt: new Date(),
    };

    this.users.set(email, user);
    return { success: true, user };
  }

  async login(email: string, password: string): Promise<AuthResult> {
    const user = this.users.get(email);

    if (!user) {
      return { success: false, error: 'Invalid credentials' };
    }

    const welcomeMessage = this.generateWelcome(user);

    return {
      success: true,
      user,
      welcomeMessage,
    };
  }

  async updateProfile(email: string, profile: UserProfile): Promise<AuthResult> {
    const user = this.users.get(email);

    if (!user) {
      return { success: false, error: 'User not found' };
    }

    user.profile = profile;
    return { success: true, user };
  }

  private generateWelcome(user: User): string {
    const name = user.profile?.displayName ?? 'there';
    const timeOfDay = this.getTimeOfDay();
    return `Good ${timeOfDay}, ${name}!`;
  }

  private getTimeOfDay(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
