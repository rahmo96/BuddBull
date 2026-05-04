const mongoose = require('mongoose');

const sportCategorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Sport name is required'],
      trim: true,
      unique: true,
      maxlength: [50, 'Sport name cannot exceed 50 characters'],
    },
    slug: {
      type: String,
      lowercase: true,
      trim: true,
      unique: true,
      index: true,
    },
    icon: {
      type: String,
      trim: true,
      default: '🏅',
    },
    color: {
      type: String,
      trim: true,
      default: '#3B82F6',
    },
    description: {
      type: String,
      trim: true,
      maxlength: [200, 'Description cannot exceed 200 characters'],
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Auto-generate slug from name
sportCategorySchema.pre('save', function (next) {
  if (this.isModified('name')) {
    this.slug = this.name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
  }
  next();
});

module.exports = mongoose.model('SportCategory', sportCategorySchema);
