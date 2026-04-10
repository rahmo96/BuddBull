/**
 * Catches any request that did not match a registered route
 * and passes a structured 404 error to the central error handler.
 */
const notFound = (req, res, next) => {
  const error = new Error(`Route not found: ${req.method} ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

module.exports = notFound;
