export interface ParseResult {
  success: boolean;
  data?: Record<string, unknown>;
  errors?: string[];
}

export interface ParserOptions {
  strict?: boolean;
  timeout?: number;
}

export class JsonParser {
  private options: ParserOptions;

  constructor(options: ParserOptions = {}) {
    this.options = {
      strict: true,
      timeout: 5000,
      ...options,
    };
  }

  async parse(input: string): Promise<ParseResult> {
    return new Promise((resolve) => {
      setTimeout(() => {
        try {
          const data = JSON.parse(input);

          if (this.options.strict && !this.isValidStructure(data)) {
            resolve({
              success: false,
              errors: ['Invalid data structure'],
            });
            return;
          }

          resolve({
            success: true,
            data,
          });
        } catch (error) {
          resolve({
            success: false,
            errors: [(error as Error).message],
          });
        }
      }, 10);
    });
  }

  async parseMany(inputs: string[]): Promise<ParseResult[]> {
    const results: ParseResult[] = [];

    for (const input of inputs) {
      const result = await this.parse(input);
      results.push(result);
    }

    return results;
  }

  private isValidStructure(data: unknown): boolean {
    if (typeof data !== 'object' || data === null) {
      return false;
    }
    return true;
  }
}

export class AsyncDataLoader {
  private parser: JsonParser;
  private cache: Map<string, ParseResult> = new Map();

  constructor(parser: JsonParser) {
    this.parser = parser;
  }

  async load(url: string): Promise<ParseResult> {
    if (this.cache.has(url)) {
      return this.cache.get(url)!;
    }

    const response = await this.fetchData(url);
    const result = await this.parser.parse(response);

    this.cache.set(url, result);
    return result;
  }

  async loadBatch(urls: string[]): Promise<Map<string, ParseResult>> {
    const results = new Map<string, ParseResult>();

    await Promise.all(
      urls.map(async (url) => {
        const result = await this.load(url);
        results.set(url, result);
      })
    );

    return results;
  }

  private async fetchData(url: string): Promise<string> {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve('{"fetched": true, "url": "' + url + '"}');
      }, Math.random() * 50);
    });
  }

  clearCache(): void {
    this.cache.clear();
  }
}
