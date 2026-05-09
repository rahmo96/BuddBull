/**
 * Firebase Admin stub used by Jest (see jest.config.js moduleNameMapper).
 * Maps synthetic bearer tokens → decoded ID tokens consumed by auth.middleware.
 *
 * Tokens must be registered before verifyIdToken is called — use registerTestDecodedToken().
 */

const registrations = new Map();

/**
 * @param {string} token Exact bearer token string (without "Bearer " prefix)
 * @param {{ uid: string, email?: string }} claims
 */
const registerTestDecodedToken = (token, claims) => {
  if (!claims?.uid) throw new Error('registerTestDecodedToken: uid required');
  registrations.set(token, {
    uid: claims.uid,
    email: claims.email ?? `${claims.uid}@test.buddbull.local`,
  });
};

const unregisterTestDecodedToken = (token) => {
  registrations.delete(token);
};

module.exports = {
  apps: [{}],
  initializeApp: jest.fn(),
  credential: {
    cert: jest.fn(),
    applicationDefault: jest.fn(),
  },
  auth: () => ({
    verifyIdToken: jest.fn(async (token) => {
      const decoded = registrations.get(token);
      if (!decoded) {
        const err = new Error('Firebase ID token has invalid signature.');
        err.code = 'auth/argument-error';
        throw err;
      }
      return { ...decoded };
    }),
  }),
  /** @deprecated Prefer registerTestDecodedToken */
  _registrations: registrations,
  registerTestDecodedToken,
  unregisterTestDecodedToken,
};
