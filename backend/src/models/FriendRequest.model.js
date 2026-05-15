const mongoose = require('mongoose');

const friendRequestSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'declined'],
      default: 'pending',
    },
  },
  { timestamps: true },
);

friendRequestSchema.index({ requester: 1, recipient: 1 }, { unique: true });
friendRequestSchema.index({ recipient: 1, status: 1 });

module.exports = mongoose.model('FriendRequest', friendRequestSchema);
