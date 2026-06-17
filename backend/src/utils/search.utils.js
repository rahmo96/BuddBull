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
    const textQuery = applyText(q);
    return await runQuery(textQuery, { useTextScore: true });
  } catch (err) {
    if (!isTextSearchError(err)) throw err;
    const regexQuery = applyRegex(q);
    return runQuery(regexQuery, { useTextScore: false });
  }
};

module.exports = {
  escapeRegExp,
  buildCaseInsensitiveRegex,
  isTextSearchError,
  runWithTextOrRegexFallback,
};
