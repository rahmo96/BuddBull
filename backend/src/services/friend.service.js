const FriendRequest = require('../models/FriendRequest.model');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const notificationInboxService = require('./notificationInbox.service');
const logger = require('../utils/logger');

const _displayName = (user) => {
  if (!user) return 'Someone';
  const full = `${user.firstName || ''} ${user.lastName || ''}`.trim();
  return full || user.username || 'Someone';
};

/** Friend IDs for a user document (supports legacy `following` storage). */
const _friendIds = (user) => {
  if (!user) return [];
  const friends = user.friends ?? [];
  if (friends.length > 0) return friends;
  return user.following ?? [];
};

const _friendsCount = (user) => _friendIds(user).length;

const areFriends = async (userIdA, userIdB) => {
  if (!userIdA || !userIdB) return false;
  if (userIdA.toString() === userIdB.toString()) return false;

  const [a, b] = await Promise.all([
    User.findById(userIdA).select('friends following').lean(),
    User.findById(userIdB).select('friends following').lean(),
  ]);
  if (!a || !b) return false;

  const aFriendsB = _friendIds(a).some((id) => id.toString() === userIdB.toString());
  const bFriendsA = _friendIds(b).some((id) => id.toString() === userIdA.toString());
  return aFriendsB && bFriendsA;
};

const _addMutualFriendship = async (userIdA, userIdB) => {
  await Promise.all([
    User.findByIdAndUpdate(userIdA, {
      $addToSet: { friends: userIdB },
      $pull: { followers: userIdB, following: userIdB },
    }),
    User.findByIdAndUpdate(userIdB, {
      $addToSet: { friends: userIdA },
      $pull: { followers: userIdA, following: userIdA },
    }),
  ]);
};

const _removeMutualFriendship = async (userIdA, userIdB) => {
  await Promise.all([
    User.findByIdAndUpdate(userIdA, {
      $pull: { friends: userIdB, followers: userIdB, following: userIdB },
    }),
    User.findByIdAndUpdate(userIdB, {
      $pull: { friends: userIdA, followers: userIdA, following: userIdA },
    }),
  ]);
};

/**
 * Viewer ↔ profile relationship for public profile UI.
 * @returns {{ isFriend, friendRequestStatus, friendRequestId }}
 *   friendRequestStatus: none | pending_sent | pending_received | friends
 */
const getRelationship = async (viewerId, profileUserId) => {
  if (!viewerId || viewerId.toString() === profileUserId.toString()) {
    return { isFriend: false, friendRequestStatus: 'none', friendRequestId: null };
  }

  if (await areFriends(viewerId, profileUserId)) {
    return { isFriend: true, friendRequestStatus: 'friends', friendRequestId: null };
  }

  const pending = await FriendRequest.findOne({
    status: 'pending',
    $or: [
      { requester: viewerId, recipient: profileUserId },
      { requester: profileUserId, recipient: viewerId },
    ],
  }).lean();

  if (!pending) {
    return { isFriend: false, friendRequestStatus: 'none', friendRequestId: null };
  }

  if (pending.requester.toString() === viewerId.toString()) {
    return {
      isFriend: false,
      friendRequestStatus: 'pending_sent',
      friendRequestId: String(pending._id),
    };
  }

  return {
    isFriend: false,
    friendRequestStatus: 'pending_received',
    friendRequestId: String(pending._id),
  };
};

const sendFriendRequest = async (requesterId, recipientId) => {
  if (requesterId.toString() === recipientId.toString()) {
    throw new AppError('You cannot send a friend request to yourself.', 400);
  }

  const [requester, recipient] = await Promise.all([
    User.findById(requesterId).active(),
    User.findById(recipientId).active().notBanned(),
  ]);

  if (!requester) throw new AppError('User not found.', 404);
  if (!recipient) throw new AppError('Target user not found.', 404);

  if (await areFriends(requesterId, recipientId)) {
    throw new AppError('You are already friends with this user.', 409);
  }

  const existing = await FriendRequest.findOne({
    requester: requesterId,
    recipient: recipientId,
  });

  if (existing?.status === 'pending') {
    throw new AppError('Friend request already sent.', 409);
  }

  let doc;
  if (existing) {
    existing.status = 'pending';
    existing.recipient = recipientId;
    existing.requester = requesterId;
    doc = await existing.save();
  } else {
    doc = await FriendRequest.create({
      requester: requesterId,
      recipient: recipientId,
      status: 'pending',
    });
  }

  const name = _displayName(requester);
  await notificationInboxService.createForUser(recipientId, {
    type: 'friendRequest',
    title: 'Friend request',
    body: `${name} sent you a friend request`,
    data: {
      userId: String(requesterId),
      requestId: String(doc._id),
      requesterName: name,
    },
  });

  logger.info(`Friend request ${doc._id}: ${requesterId} → ${recipientId}`);
  return { requestId: String(doc._id), status: 'pending' };
};

const acceptFriendRequest = async (actorId, requestId) => {
  const req = await FriendRequest.findById(requestId);
  if (!req) throw new AppError('Friend request not found.', 404);
  if (req.recipient.toString() !== actorId.toString()) {
    throw new AppError('Only the recipient can accept this request.', 403);
  }
  if (req.status !== 'pending') {
    throw new AppError('This friend request is no longer pending.', 400);
  }

  req.status = 'accepted';
  await req.save();

  await _addMutualFriendship(req.requester, req.recipient);

  const recipient = await User.findById(req.recipient).select('firstName lastName username');
  const name = _displayName(recipient);
  await notificationInboxService.createForUser(req.requester, {
    type: 'friendRequestAccepted',
    title: 'Friend request accepted',
    body: `${name} accepted your friend request`,
    data: {
      userId: String(req.recipient),
      requestId: String(req._id),
    },
  });

  const target = await User.findById(req.recipient).select('friends following').lean();
  return {
    isFriend: true,
    friendRequestStatus: 'friends',
    friendsCount: _friendsCount(target),
  };
};

const declineFriendRequest = async (actorId, requestId) => {
  const req = await FriendRequest.findById(requestId);
  if (!req) throw new AppError('Friend request not found.', 404);
  if (req.recipient.toString() !== actorId.toString()) {
    throw new AppError('Only the recipient can decline this request.', 403);
  }
  if (req.status !== 'pending') {
    throw new AppError('This friend request is no longer pending.', 400);
  }

  req.status = 'declined';
  await req.save();
  return { status: 'declined' };
};

const unfriend = async (actorId, targetId) => {
  if (actorId.toString() === targetId.toString()) {
    throw new AppError('Invalid operation.', 400);
  }

  await _removeMutualFriendship(actorId, targetId);

  await FriendRequest.deleteMany({
    $or: [
      { requester: actorId, recipient: targetId },
      { requester: targetId, recipient: actorId },
    ],
  });

  const target = await User.findById(targetId).select('friends following').lean();
  return { friendsCount: _friendsCount(target) };
};

/** Approved mutual friends. */
const getFriends = async (userId, { page = 1, limit = 50 } = {}) => {
  const user = await User.findById(userId)
    .select('friends following')
    .active()
    .lean();

  if (!user) throw new AppError('User not found.', 404);

  const friendPath = (user.friends?.length ?? 0) > 0 ? 'friends' : 'following';

  const populated = await User.findById(userId)
    .populate({
      path: friendPath,
      select: 'username firstName lastName profilePicture stats.averageRating',
      options: {
        skip: (page - 1) * limit,
        limit: Number(limit),
      },
    })
    .active()
    .lean();

  return populated?.[friendPath] ?? [];
};

module.exports = {
  areFriends,
  getRelationship,
  sendFriendRequest,
  acceptFriendRequest,
  declineFriendRequest,
  unfriend,
  getFriends,
  _friendsCount,
};
