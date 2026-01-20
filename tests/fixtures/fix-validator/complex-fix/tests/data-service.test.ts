import { DataService } from '../src/data-service';

describe('DataService', () => {
  let service: DataService;

  beforeEach(() => {
    service = new DataService();
  });

  describe('fetchSingle', () => {
    it('should fetch and cache data', async () => {
      const result = await service.fetchSingle('https://api.example.com/data');

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
    });

    it('should return cached data on second call', async () => {
      const url = 'https://api.example.com/cached';

      const first = await service.fetchSingle(url);
      const second = await service.fetchSingle(url);

      expect(first).toBe(second);
    });

    it('should validate schema when enabled', async () => {
      const service = new DataService({ validateSchema: true });
      const result = await service.fetchSingle('https://api.example.com/data');

      expect(result.success).toBe(true);
    });
  });

  describe('fetchBatch', () => {
    it('should fetch multiple URLs', async () => {
      const urls = [
        'https://api.example.com/1',
        'https://api.example.com/2',
        'https://api.example.com/3',
      ];

      const results = await service.fetchBatch(urls);

      expect(results.size).toBe(3);
      for (const result of results.values()) {
        expect(result.success).toBe(true);
      }
    });

    it('should complete all requests before returning', async () => {
      const urls = Array.from({ length: 10 }, (_, i) => `https://api.example.com/${i}`);

      const results = await service.fetchBatch(urls);

      expect(results.size).toBe(10);

      for (const [url, result] of results) {
        expect(result.success).toBe(true);
        expect(result.data).toBeDefined();
      }
    });

    it('should handle concurrent requests efficiently', async () => {
      const urls = Array.from({ length: 5 }, (_, i) => `https://api.example.com/concurrent/${i}`);

      const startTime = Date.now();
      const results = await service.fetchBatch(urls);
      const elapsed = Date.now() - startTime;

      expect(results.size).toBe(5);
      expect(elapsed).toBeLessThan(250);
    });
  });

  describe('generateReport', () => {
    it('should generate report from multiple sources', async () => {
      const urls = ['https://api.example.com/source1', 'https://api.example.com/source2'];

      const report = await service.generateReport(urls);

      expect(report).toContain('2/2 sources loaded successfully');
    });
  });

  describe('aggregateData', () => {
    it('should aggregate data from multiple URLs', async () => {
      const urls = ['https://api.example.com/a', 'https://api.example.com/b'];

      const result = await service.aggregateData(urls);

      expect(result.success).toBe(true);
      expect(Object.keys(result.data!)).toHaveLength(2);
    });
  });

  describe('validateSources', () => {
    it('should categorize valid and invalid sources', async () => {
      const urls = ['https://api.example.com/valid1', 'https://api.example.com/valid2'];

      const { valid, invalid } = await service.validateSources(urls);

      expect(valid).toHaveLength(2);
      expect(invalid).toHaveLength(0);
    });
  });

  describe('prefetchUrls', () => {
    it('should prefetch and return success count', async () => {
      const urls = ['https://api.example.com/pre1', 'https://api.example.com/pre2'];

      const count = await service.prefetchUrls(urls);

      expect(count).toBe(2);
    });
  });

  describe('clearCache', () => {
    it('should clear the cache', async () => {
      const url = 'https://api.example.com/clear-test';

      await service.fetchSingle(url);
      service.clearCache();

      const result = await service.fetchSingle(url);
      expect(result.success).toBe(true);
    });
  });
});
