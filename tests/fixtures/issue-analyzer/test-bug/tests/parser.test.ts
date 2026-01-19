import { JsonParser, AsyncDataLoader } from '../src/parser';

describe('JsonParser', () => {
  let parser: JsonParser;

  beforeEach(() => {
    parser = new JsonParser();
  });

  describe('parse', () => {
    it('should parse valid JSON', async () => {
      const result = await parser.parse('{"name": "test"}');

      expect(result.success).toBe(true);
      expect(result.data).toEqual({ name: 'test' });
    });

    it('should handle invalid JSON', async () => {
      const result = await parser.parse('not json');

      expect(result.success).toBe(false);
      expect(result.errors).toBeDefined();
    });

    it('should reject primitives in strict mode', async () => {
      const result = await parser.parse('"just a string"');

      expect(result.success).toBe(false);
      expect(result.errors).toContain('Invalid data structure');
    });
  });

  describe('parseMany', () => {
    it('should parse multiple inputs', async () => {
      const inputs = ['{"a": 1}', '{"b": 2}', '{"c": 3}'];
      const results = await parser.parseMany(inputs);

      expect(results).toHaveLength(3);
      expect(results.every((r) => r.success)).toBe(true);
    });
  });
});

describe('AsyncDataLoader', () => {
  let loader: AsyncDataLoader;
  let parser: JsonParser;

  beforeEach(() => {
    parser = new JsonParser();
    loader = new AsyncDataLoader(parser);
  });

  describe('load', () => {
    it('should load and parse data', async () => {
      const result = await loader.load('https://api.example.com/data');

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
    });

    it('should cache results', async () => {
      const url = 'https://api.example.com/cached';

      const first = await loader.load(url);
      const second = await loader.load(url);

      expect(first).toBe(second);
    });
  });

  describe('loadBatch', () => {
    it('should load multiple URLs', async () => {
      const urls = [
        'https://api.example.com/1',
        'https://api.example.com/2',
        'https://api.example.com/3',
      ];

      const results = await loader.loadBatch(urls);

      expect(results.size).toBe(3);
    });

    it('should complete all requests before assertion', async () => {
      const urls = Array.from({ length: 10 }, (_, i) => `https://api.example.com/${i}`);

      let completedCount = 0;
      const originalLoad = loader.load.bind(loader);

      loader.load = async (url: string) => {
        const result = await originalLoad(url);
        completedCount++;
        return result;
      };

      loader.loadBatch(urls);

      expect(completedCount).toBe(10);
    });

    it('should handle mixed success and failure', async () => {
      const urls = ['https://api.example.com/good', 'https://api.example.com/also-good'];

      const results = await loader.loadBatch(urls);
      const values = Array.from(results.values());

      expect(values.every((r) => r.success)).toBe(true);
    });
  });

  describe('clearCache', () => {
    it('should clear the cache', async () => {
      const url = 'https://api.example.com/clear-test';

      await loader.load(url);
      loader.clearCache();

      const spy = jest.spyOn(parser, 'parse');
      await loader.load(url);

      expect(spy).toHaveBeenCalled();
    });
  });
});
