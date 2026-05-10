const request = require('supertest');
const { registerTestDecodedToken, unregisterTestDecodedToken } = require('firebase-admin');

let seq = 0;

/**
 * Registers a deterministic Firebase decoded-token mapping and completes POST /auth/sync.
 *
 * @param {import('express').Application | import('@types/express').Application} app
 * @param {object} [opts]
 * @param {'player'|'organizer'|'admin'} [opts.role]
 */
const syncFirebaseUser = async (app, opts = {}) => {
  seq += 1;
  const uid = opts.firebaseUid ?? `fb-test-${seq}`;
  const email = opts.email ?? `sportuser${seq}@integration.test`;
  const bearer = opts.bearerToken ?? `jwt-like-test-token-${uid}`;

  registerTestDecodedToken(bearer, { uid, email });

  const username = opts.username ?? `sportusr_${seq}_${process.hrtime.bigint()}`;
  const body = {
    firstName: opts.firstName ?? 'Integration',
    lastName: opts.lastName ?? `User${seq}`,
    username,
    role: opts.role ?? 'player',
  };

  const res = await request(app).post('/api/v1/auth/sync').set('Authorization', `Bearer ${bearer}`).send(body);

  const user = res.body?.data?.user;
  if (res.status >= 400) {
    unregisterTestDecodedToken(bearer);
  }

  return {
    bearer,
    firebaseUid: uid,
    email,
    status: res.status,
    body: res.body,
    user,
    userId: user?._id,
    token: bearer,
  };
};

module.exports = {
  syncFirebaseUser,
};
