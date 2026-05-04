import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays approved players as stacked avatars + pending count.
class PlayerAvatarRow extends StatelessWidget {
  const PlayerAvatarRow({
    super.key,
    required this.players,
    required this.maxPlayers,
    this.showPending = true,
  });

  final List<GamePlayer> players;
  final int maxPlayers;
  final bool showPending;

  @override
  Widget build(BuildContext context) {
    final approved =
        players.where((p) => p.isApproved).toList();
    final pending =
        players.where((p) => p.isPending).toList();
    const avatarSize = 32.0;
    const overlap = 10.0;
    final displayCount = approved.length.clamp(0, 5);
    final extraCount = approved.length - displayCount;

    return Row(
      children: [
        // ── Stacked approved avatars ─────────────────────────
        SizedBox(
          height: avatarSize,
          width: displayCount * (avatarSize - overlap) + avatarSize,
          child: Stack(
            children: [
              for (int i = 0; i < displayCount; i++)
                Positioned(
                  left: i * (avatarSize - overlap),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                    ),
                    child: _MiniAvatar(
                      player: approved[i],
                      size: avatarSize,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (extraCount > 0) ...[
          const SizedBox(width: 4),
          Text('+$extraCount', style: AppTextStyles.labelSmall),
        ],

        const SizedBox(width: 8),

        // ── Slot indicator ────────────────────────────────────
        Text(
          '${approved.length}/$maxPlayers players',
          style: AppTextStyles.bodySmall,
        ),

        if (showPending && pending.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${pending.length} pending',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.player, required this.size});
  final GamePlayer player;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (player.profilePicture != null) {
      return CircleAvatar(
        radius: size / 2,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: player.profilePicture!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _Initials(player: player, size: size),
          ),
        ),
      );
    }
    return _Initials(player: player, size: size);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.player, required this.size});
  final GamePlayer player;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = player.firstName?.isNotEmpty == true
        ? player.firstName![0]
        : player.username[0];
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withOpacity(0.2),
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
