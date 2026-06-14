/**
 * BuddBull — Agenda scheduler (MongoDB-backed job queue).
 *
 * Used for one-off pre-game reminder jobs that survive server restarts.
 * Recurring jobs (daily retention) use node-cron in server.js instead.
 */

const Agenda = require('agenda');
const logger = require('../utils/logger');
const { mongoUri } = require('./environment');

const AGENDA_COLLECTION = 'agendaJobs';
const JOB_SEND_PRE_GAME_REMINDER = 'send-pre-game-reminder';

let _agenda = null;

/**
 * Creates and starts the Agenda instance. Idempotent — returns the same
 * instance on subsequent calls.
 *
 * @returns {Promise<import('agenda').Agenda>}
 */
const initAgenda = async () => {
  if (_agenda) return _agenda;

  const agenda = new Agenda({
    db: { address: mongoUri, collection: AGENDA_COLLECTION },
    processEvery: '30 seconds',
    maxConcurrency: 5,
    defaultConcurrency: 3,
  });

  agenda.on('ready', () => logger.info('[Agenda] Connected to MongoDB ✓'));
  agenda.on('error', (err) => logger.error(`[Agenda] Error: ${err.message}`));
  agenda.on('fail', (err, job) => {
    logger.error(`[Agenda] Job "${job?.attrs?.name}" failed: ${err.message}`);
  });

  await agenda.start();
  _agenda = agenda;
  return agenda;
};

/**
 * Returns the running Agenda instance, or null if not yet initialised.
 *
 * @returns {import('agenda').Agenda | null}
 */
const getAgenda = () => _agenda;

/**
 * Gracefully stops Agenda (drains in-flight jobs).
 */
const shutdownAgenda = async () => {
  if (!_agenda) return;
  logger.info('[Agenda] Shutting down…');
  await _agenda.stop();
  _agenda = null;
};

module.exports = {
  AGENDA_COLLECTION,
  JOB_SEND_PRE_GAME_REMINDER,
  initAgenda,
  getAgenda,
  shutdownAgenda,
};
