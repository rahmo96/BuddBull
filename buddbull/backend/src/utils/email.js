const nodemailer = require('nodemailer');
const { email: emailConfig, nodeEnv } = require('../config/environment');
const logger = require('./logger');

// ─────────────────────────────────────────────
//  Transporter factory
// ─────────────────────────────────────────────

const createTransporter = () => {
  if (nodeEnv === 'test') {
    // In tests, use a no-op transport so no real emails are sent
    return nodemailer.createTransport({ jsonTransport: true });
  }

  return nodemailer.createTransport({
    host: emailConfig.host,
    port: emailConfig.port,
    secure: emailConfig.secure,
    auth: {
      user: emailConfig.user,
      pass: emailConfig.pass,
    },
  });
};

const transporter = createTransporter();

// ─────────────────────────────────────────────
//  HTML template builder
// ─────────────────────────────────────────────

/**
 * Shared HTML shell for all transactional emails.
 * Keeps brand consistent without a template engine dependency.
 */
const buildHtml = (title, bodyHtml) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title}</title>
  <style>
    body { margin: 0; padding: 0; background: #f4f7f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
    .wrapper { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,.08); }
    .header { background: linear-gradient(135deg, #ff6b35 0%, #f7c948 100%); padding: 32px 40px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px; }
    .header p  { color: rgba(255,255,255,.85); margin: 6px 0 0; font-size: 14px; }
    .body { padding: 40px; color: #374151; line-height: 1.65; }
    .body h2   { color: #111827; margin: 0 0 16px; font-size: 22px; }
    .body p    { margin: 0 0 16px; font-size: 15px; }
    .btn { display: inline-block; padding: 14px 32px; background: #ff6b35; color: #ffffff !important; border-radius: 8px; text-decoration: none; font-weight: 700; font-size: 15px; margin: 8px 0 24px; }
    .btn:hover { background: #e85c26; }
    .token-box { background: #f3f4f6; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px 20px; font-family: monospace; font-size: 22px; letter-spacing: 4px; text-align: center; color: #111827; margin: 16px 0 24px; }
    .footer { background: #f9fafb; padding: 24px 40px; text-align: center; font-size: 12px; color: #9ca3af; border-top: 1px solid #f3f4f6; }
    .footer a { color: #ff6b35; text-decoration: none; }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <h1>BuddBull</h1>
      <p>Social-Sport Platform</p>
    </div>
    <div class="body">
      ${bodyHtml}
    </div>
    <div class="footer">
      <p>You received this email because an action was performed on your BuddBull account.</p>
      <p>If you didn't request this, please <a href="mailto:support@buddbull.app">contact support</a>.</p>
      <p>&copy; ${new Date().getFullYear()} BuddBull. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
`;

// ─────────────────────────────────────────────
//  Email templates
// ─────────────────────────────────────────────

const templates = {
  verifyEmail: ({ firstName, verificationUrl }) => ({
    subject: 'Verify your BuddBull account',
    html: buildHtml(
      'Verify your email',
      `
      <h2>Welcome to BuddBull, ${firstName}! 🏆</h2>
      <p>You're one step away from joining thousands of players. Please verify your email address to activate your account.</p>
      <p style="text-align:center">
        <a href="${verificationUrl}" class="btn">Verify my email</a>
      </p>
      <p>Or copy and paste this link into your browser:</p>
      <p style="word-break:break-all; font-size:13px; color:#6b7280">${verificationUrl}</p>
      <p>This link expires in <strong>24 hours</strong>.</p>
      `,
    ),
  }),

  forgotPassword: ({ firstName, resetUrl, expiresInMinutes }) => ({
    subject: 'Reset your BuddBull password',
    html: buildHtml(
      'Password reset',
      `
      <h2>Forgot your password, ${firstName}?</h2>
      <p>No worries — it happens to the best of us. Click the button below to choose a new password.</p>
      <p style="text-align:center">
        <a href="${resetUrl}" class="btn">Reset my password</a>
      </p>
      <p>Or copy this link into your browser:</p>
      <p style="word-break:break-all; font-size:13px; color:#6b7280">${resetUrl}</p>
      <p>This link expires in <strong>${expiresInMinutes} minutes</strong>. If you didn't request a password reset, you can safely ignore this email.</p>
      `,
    ),
  }),

  passwordChanged: ({ firstName }) => ({
    subject: 'Your BuddBull password was changed',
    html: buildHtml(
      'Password changed',
      `
      <h2>Password updated, ${firstName}</h2>
      <p>Your BuddBull password was successfully changed.</p>
      <p>If you made this change, no further action is needed.</p>
      <p>If you did <strong>not</strong> make this change, please <a href="mailto:support@buddbull.app" style="color:#ff6b35">contact our support team immediately</a>.</p>
      `,
    ),
  }),

  gameInvite: ({ firstName, inviterName, gameName, gameDate, acceptUrl }) => ({
    subject: `${inviterName} invited you to play!`,
    html: buildHtml(
      'Game invite',
      `
      <h2>You've been invited, ${firstName}!</h2>
      <p><strong>${inviterName}</strong> has invited you to join:</p>
      <div class="token-box">${gameName}</div>
      <p>Scheduled for: <strong>${gameDate}</strong></p>
      <p style="text-align:center">
        <a href="${acceptUrl}" class="btn">View &amp; Accept Invite</a>
      </p>
      `,
    ),
  }),

  welcome: ({ firstName }) => ({
    subject: 'Welcome to BuddBull 🏆',
    html: buildHtml(
      'Welcome',
      `
      <h2>You're in, ${firstName}!</h2>
      <p>Your account is verified. Here's what you can do right now:</p>
      <ul style="padding-left:20px; color:#374151; font-size:15px; line-height:2">
        <li>Complete your profile and add your sports interests</li>
        <li>Search for games near you</li>
        <li>Create your own match and invite players</li>
        <li>Track your stats and streaks in the Performance Center</li>
      </ul>
      <p style="text-align:center; margin-top:24px">
        <a href="${process.env.CLIENT_URL || 'https://buddbull.app'}" class="btn">Open BuddBull</a>
      </p>
      `,
    ),
  }),
};

// ─────────────────────────────────────────────
//  Send helper
// ─────────────────────────────────────────────

/**
 * Sends a transactional email.
 *
 * @param {string}  to        recipient email address
 * @param {string}  template  key from the templates object above
 * @param {object}  data      variables injected into the template
 */
const sendEmail = async (to, template, data) => {
  const { subject, html } = templates[template](data);

  const mailOptions = {
    from: emailConfig.from,
    to,
    subject,
    html,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    logger.info(`Email sent [${template}] → ${to} (${info.messageId})`);
    return info;
  } catch (err) {
    logger.error(`Email failed [${template}] → ${to}: ${err.message}`);
    throw err;
  }
};

module.exports = { sendEmail };
