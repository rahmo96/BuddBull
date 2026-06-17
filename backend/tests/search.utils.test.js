const {
  buildCaseInsensitiveRegex,
  isTextSearchError,
  runWithTextOrRegexFallback,
} = require('../src/utils/search.utils');

describe('search.utils', () => {
  describe('buildCaseInsensitiveRegex', () => {
    it('escapes regex metacharacters in the query', () => {
      const regex = buildCaseInsensitiveRegex('a+b(c)');
      expect('a+b(c)'.match(regex)).not.toBeNull();
      expect('abc'.match(regex)).toBeNull();
    });
  });

  describe('isTextSearchError', () => {
    it('detects missing text index errors', () => {
      expect(isTextSearchError(new Error('needs a text index'))).toBe(true);
      expect(isTextSearchError(new Error('network down'))).toBe(false);
    });
  });

  describe('runWithTextOrRegexFallback', () => {
    it('returns text results when the index yields hits', async () => {
      const runQuery = jest
        .fn()
        .mockResolvedValueOnce({ users: [{ _id: '1' }], pagination: { total: 1 } });

      const result = await runWithTextOrRegexFallback({
        q: 'alex',
        applyText: (term) => ({ $text: { $search: term } }),
        applyRegex: (term) => ({ username: buildCaseInsensitiveRegex(term) }),
        runQuery,
      });

      expect(result.pagination.total).toBe(1);
      expect(runQuery).toHaveBeenCalledTimes(1);
    });

    it('falls back to regex when text search returns zero rows', async () => {
      const runQuery = jest
        .fn()
        .mockResolvedValueOnce({ users: [], pagination: { total: 0 } })
        .mockResolvedValueOnce({ users: [{ _id: '2' }], pagination: { total: 1 } });

      const result = await runWithTextOrRegexFallback({
        q: 'goalkeeper',
        applyText: (term) => ({ $text: { $search: term } }),
        applyRegex: (term) => ({ username: buildCaseInsensitiveRegex(term) }),
        runQuery,
      });

      expect(result.pagination.total).toBe(1);
      expect(runQuery).toHaveBeenCalledTimes(2);
      expect(runQuery.mock.calls[1][1]).toEqual({ useTextScore: false });
    });

    it('falls back to regex when the text index is unavailable', async () => {
      const runQuery = jest
        .fn()
        .mockRejectedValueOnce(new Error('text index required for $text'))
        .mockResolvedValueOnce({ users: [{ _id: '3' }], pagination: { total: 1 } });

      const result = await runWithTextOrRegexFallback({
        q: 'keeper',
        applyText: (term) => ({ $text: { $search: term } }),
        applyRegex: (term) => ({ username: buildCaseInsensitiveRegex(term) }),
        runQuery,
      });

      expect(result.pagination.total).toBe(1);
      expect(runQuery).toHaveBeenCalledTimes(2);
    });
  });
});
