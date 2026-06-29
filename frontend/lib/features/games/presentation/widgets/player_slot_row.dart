import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/profile/presentation/widgets/bb_profile_avatar.dart';
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
    final l10n = context.l10n;
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
          Text(l10n.extraPlayersCount(extraCount),
              style: AppTextStyles.labelSmall),
        ],

        const SizedBox(width: 8),

        // ── Slot indicator ────────────────────────────────────
        Text(
          l10n.playersCountLabel(approved.length, maxPlayers),
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
              l10n.pendingRequestsCount(pending.length),
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

  String _initials(GamePlayer p) {
    final fn = p.firstName;
    final ln = p.lastName;
    if (fn != null &&
        fn.isNotEmpty &&
        ln != null &&
        ln.isNotEmpty) {
      return '${fn[0]}${ln[0]}';
    }
    if (fn != null && fn.isNotEmpty) return fn[0];
    final u = p.username;
    if (u.isEmpty) return '?';
    return u.length >= 2 ? u.substring(0, 2) : u[0];
  }

  @override
  Widget build(BuildContext context) {
    return BbProfileAvatar(
      profilePicture: player.profilePicture,
      initials: _initials(player),
      radius: size / 2,
    );
  }
}
