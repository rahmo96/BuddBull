/**
 * Minimal CSV builder — no external dependencies.
 * Handles nested values via dot-notation field paths.
 */

// Safely resolve a dot-notation path from an object
const getValue = (obj, path) => {
  const val = path.split('.').reduce((acc, key) => (acc != null ? acc[key] : ''), obj);
  if (val === null || val === undefined) return '';
  if (val instanceof Date) return val.toISOString();
  return String(val);
};

// Escape a cell value for CSV (RFC 4180)
const escapeCell = (value) => {
  const str = String(value ?? '');
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
};

/**
 * Convert an array of objects to a CSV string.
 *
 * @param {Array<Object>} rows        - The data rows
 * @param {Array<{label: string, path: string}>} columns - Column definitions
 * @returns {string} CSV text with CRLF line endings
 */
const toCSV = (rows, columns) => {
  const header = columns.map((c) => escapeCell(c.label)).join(',');
  const lines = rows.map((row) =>
    columns.map((c) => escapeCell(getValue(row, c.path))).join(','),
  );
  return [header, ...lines].join('\r\n');
};

module.exports = { toCSV };
