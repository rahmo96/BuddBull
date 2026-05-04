/**
 * Operational error class — represents expected, user-facing errors
 * (4xx and known 5xx). Non-operational errors (bugs, unexpected crashes)
 * are plain Error objects and should never reach the client.
 *
 * Usage:
 *   throw new AppError('Email already registered', 409);
 *   next(new AppError('Not authorised', 401));
 */
class AppError extends Error {
  /**
   * @param {string} message   Human-readable message sent to the client
   * @param {number} statusCode HTTP status code
   */
  constructor(message, statusCode) {
    super(message);

    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    // Preserve a clean stack trace that excludes this constructor frame
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
