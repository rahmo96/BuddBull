/**
 * Wraps an async Express route handler so that any rejected promise
 * is automatically forwarded to the centralized error handler via next().
 *
 * This eliminates repetitive try/catch boilerplate in every controller.
 *
 * Usage:
 *   router.get('/me', catchAsync(async (req, res) => {
 *     const user = await UserService.getById(req.user.id);
 *     res.json(user);
 *   }));
 */
const catchAsync = (fn) => (req, res, next) => {
  fn(req, res, next).catch(next);
};

module.exports = catchAsync;
