export interface DataResult {
  success: boolean;
  data?: Record<string, unknown>;
  errors?: string[];
}

export interface ServiceOptions {
  timeout?: number;
  retryCount?: number;
  validateSchema?: boolean;
}

export class DataService {
  private options: ServiceOptions;
  private cache: Map<string, DataResult> = new Map();

  constructor(options: ServiceOptions = {}) {
    this.options = {
      timeout: 5000,
      retryCount: 3,
      validateSchema: true,
      ...options,
    };
  }

  async fetchSingle(url: string): Promise<DataResult> {
    if (this.cache.has(url)) {
      return this.cache.get(url)!;
    }

    try {
      const data = await this.performFetch(url);
      const result: DataResult = { success: true, data };

      if (this.options.validateSchema && !this.isValidSchema(data)) {
        return { success: false, errors: ['Schema validation failed'] };
      }

      this.cache.set(url, result);
      return result;
    } catch (error) {
      return { success: false, errors: [(error as Error).message] };
    }
  }

  async fetchBatch(urls: string[]): Promise<Map<string, DataResult>> {
    const results = new Map<string, DataResult>();

    await Promise.all(
      urls.map(async (url) => {
        const result = await this.fetchSingle(url);
        results.set(url, result);
      })
    );

    return results;
  }

  async generateReport(sourceUrls: string[]): Promise<string> {
    const results = await this.fetchBatch(sourceUrls);
    const successCount = Array.from(results.values()).filter(r => r.success).length;
    return `Report: ${successCount}/${sourceUrls.length} sources loaded successfully`;
  }

  async aggregateData(urls: string[]): Promise<DataResult> {
    const results = await this.fetchBatch(urls);
    const allData: Record<string, unknown> = {};

    for (const [url, result] of results) {
      if (result.success && result.data) {
        allData[url] = result.data;
      }
    }

    return { success: true, data: allData };
  }

  async validateSources(urls: string[]): Promise<{ valid: string[]; invalid: string[] }> {
    const valid: string[] = [];
    const invalid: string[] = [];

    for (const url of urls) {
      const result = await this.fetchSingle(url);
      if (result.success) {
        valid.push(url);
      } else {
        invalid.push(url);
      }
    }

    return { valid, invalid };
  }

  async prefetchUrls(urls: string[]): Promise<number> {
    const results = await this.fetchBatch(urls);
    return Array.from(results.values()).filter(r => r.success).length;
  }

  private async performFetch(url: string): Promise<Record<string, unknown>> {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({ fetched: true, url, timestamp: Date.now() });
      }, Math.random() * 50);
    });
  }

  private isValidSchema(data: unknown): boolean {
    if (typeof data !== 'object' || data === null) {
      return false;
    }
    return true;
  }

  clearCache(): void {
    this.cache.clear();
  }
}
