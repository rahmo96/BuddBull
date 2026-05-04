const multer = require('multer');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs');
const AppError = require('../utils/AppError');
const { upload: uploadConfig } = require('../config/environment');

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
const MAX_PROFILE_PIC_SIZE = 5 * 1024 * 1024; // 5 MB

/**
 * Generates a unique, collision-resistant filename.
 * Format: <userId>-<timestamp>-<random>.<ext>
 */
const uniqueFilename = (userId, originalName) => {
  const ext = path.extname(originalName).toLowerCase();
  const rand = crypto.randomBytes(8).toString('hex');
  return `${userId}-${Date.now()}-${rand}${ext}`;
};

/**
 * Ensures the upload directory exists (creates it recursively if not).
 */
const ensureDir = (dir) => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
};

// ─────────────────────────────────────────────
//  File filter  (shared across all upload configs)
// ─────────────────────────────────────────────

const imageFilter = (req, file, cb) => {
  if (ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new AppError('Only JPEG, PNG, and WebP images are allowed.', 415), false);
  }
};

// ─────────────────────────────────────────────
//  Local disk storage  (development)
// ─────────────────────name───────────────────

const profilePicDir = path.join(process.cwd(), uploadConfig.dir, 'profiles');
ensureDir(profilePicDir);

const diskStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    ensureDir(profilePicDir);
    cb(null, profilePicDir);
  },
  filename: (req, file, cb) => {
    const userId = req.user?._id?.toString() || 'anonymous';
    cb(null, uniqueFilename(userId, file.originalname));
  },
});

// ─────────────────────────────────────────────
//  Memory storage  (for S3 / future cloud upload)
// ─────────────────────────────────────────────

const memoryStorage = multer.memoryStorage();

// ─────────────────────────────────────────────
//  Multer instances
// ─────────────────────────────────────────────

/**
 * Profile picture upload — single file, disk storage (local) or
 * memory storage (cloud).
 */
const uploadProfilePicture = multer({
  storage: uploadConfig.driver === 's3' ? memoryStorage : diskStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: MAX_PROFILE_PIC_SIZE,
    files: 1,
  },
}).single('profilePicture');

/**
 * Wraps multer in a promise so errors are forwarded to the
 * centralized Express error handler via next(err).
 */
const handleProfilePicUpload = (req, res, next) => {
  uploadProfilePicture(req, res, (err) => {
    if (!err) return next();

    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return next(new AppError(`Profile picture must be smaller than ${MAX_PROFILE_PIC_SIZE / (1024 * 1024)} MB.`, 413));
      }
      return next(new AppError(`Upload error: ${err.message}`, 400));
    }

    // Pass AppError instances (from fileFilter) directly
    return next(err);
  });
};

/**
 * Game / performance log media — up to 5 images.
 */
const gameMedaDir = path.join(process.cwd(), uploadConfig.dir, 'games');
ensureDir(gameMedaDir);

const gameMediaStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    ensureDir(gameMedaDir);
    cb(null, gameMedaDir);
  },
  filename: (req, file, cb) => {
    const userId = req.user?._id?.toString() || 'anonymous';
    cb(null, uniqueFilename(userId, file.originalname));
  },
});

const handleGameMediaUpload = multer({
  storage: uploadConfig.driver === 's3' ? memoryStorage : gameMediaStorage,
  fileFilter: imageFilter,
  limits: { fileSize: 10 * 1024 * 1024, files: 5 },
}).array('media', 5);

module.exports = {
  handleProfilePicUpload,
  handleGameMediaUpload,
  uniqueFilename,
  profilePicDir,
};
