/**
 * Helpers for user/game discovery search.
 */

const escapeRegExp = (value) =>
  String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const buildCaseInsensitiveRegex = (value) =>
  new RegExp(escapeRegExp(String(value).trim()), 'i');

const isTextSearchError = (err) => {
  const message = err?.message || '';
  return /text index|needs a text index|\$text/i.test(message);
};

const runWithTextOrRegexFallback = async ({
  q,
  applyText,
  applyRegex,
  runQuery,
}) => {
  if (!q) {
    return runQuery();
  }

  try {
    const textResult = await runQuery(applyText(q), { useTextScore: true });
    // Text indexes tokenize words — substring queries like "goal" inside
    // "goalkeeper" may yield zero hits without erroring. Fall back to regex
    // so discovery search stays predictable in tests and production.
    if ((textResult.pagination?.total ?? 0) > 0) {
      return textResult;
    }
  } catch (err) {
    if (!isTextSearchError(err)) throw err;
  }

  return runQuery(applyRegex(q), { useTextScore: false });
};

module.exports = {
  escapeRegExp,
  buildCaseInsensitiveRegex,
  isTextSearchError,
  runWithTextOrRegexFallback,
};
