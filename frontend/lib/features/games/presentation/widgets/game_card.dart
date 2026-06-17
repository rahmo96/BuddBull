import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/game_sport_wallpaper.dart';
import 'package:flutter/material.dart';

/// A rich game card used in the games list and home screen.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.onJoin,
    this.compact = false,
    this.showJoinButton = false,
  });

  final GameModel game;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final bool compact;
  final bool showJoinButton;

  bool get _canJoin =>
      showJoinButton &&
      onJoin != null &&
      game.status == 'open' &&
      !game.isFull &&
      !game.isCompleted &&
      !game.isCancelled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            boxShadow: AppColors.cardShadow,
          ),
          child: compact
              ? _CompactContent(game: game)
              : _FullContent(game: game, canJoin: _canJoin, onJoin: onJoin),
        ),
      ),
    );
  }
}

class _FullContent extends StatelessWidget {
  const _FullContent({
    required this.game,
    required this.canJoin,
    this.onJoin,
  });

  final GameModel game;
  final bool canJoin;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameSportWallpaper(
          sport: game.sport,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusMd),
          ),
          child: _GameNameHeader(game: game),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.info,
                text: '${game.formattedDate} · ${game.formattedTime}',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.metricStreakAccent,
                text: game.location.displayName,
              ),
              if (game.distanceKm != null) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.near_me_rounded,
                  iconColor: AppColors.teal,
                  text: _formatDistance(game.distanceKm!),
                ),
              ],
              const SizedBox(height: 14),
              _RosterProgressBar(
                filled: game.approvedCount,
                total: game.maxPlayers,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SkillBadge(level: game.requiredSkillLevel),
                  const Spacer(),
                  if (canJoin)
                    FilledButton(
                      onPressed: onJoin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.slate,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Join Game',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${game.approvedCount}/${game.maxPlayers} players',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.game});
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameSportWallpaper(
            sport: game.sport,
            height: 88,
            padding: const EdgeInsets.all(14),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppColors.radiusMd),
            ),
            child: _GameNameHeader(game: game, compact: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${game.formattedDate} · ${game.formattedTime}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                _RosterProgressBar(
                  filled: game.approvedCount,
                  total: game.maxPlayers,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameNameHeader extends StatelessWidget {
  const _GameNameHeader({required this.game, this.compact = false});

  final GameModel game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                game.title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (game.isPrivate || game.requiresApproval) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_rounded,
                size: compact ? 13 : 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
            const SizedBox(width: 8),
            if (game.isFull && !game.isCompleted && !game.isCancelled)
              _FullBadge(small: compact, onWallpaper: true)
            else
              _StatusBadge(
                status: game.status,
                small: compact,
                onWallpaper: true,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          game.sport,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RosterProgressBar extends StatelessWidget {
  const _RosterProgressBar({
    required this.filled,
    required this.total,
    this.compact = false,
  });

  final int filled;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? filled / total : 0.0;
    final color = fraction >= 1
        ? AppColors.statusFull
        : fraction >= 0.75
            ? AppColors.warning
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Roster',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$filled/$total players',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: compact ? 6 : 10,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    this.small = false,
    this.onWallpaper = false,
  });
  final String status;
  final bool small;
  final bool onWallpaper;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'open' => (AppColors.statusOpen, 'Open'),
      'full' => (AppColors.statusFull, 'Full'),
      'in_progress' => (AppColors.statusInProgress, 'Live'),
      'completed' => (AppColors.statusCompleted, 'Done'),
      'cancelled' => (AppColors.statusCancelled, 'Cancelled'),
      _ => (AppColors.grey500, status),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: onWallpaper
            ? Colors.white.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: (small ? AppTextStyles.labelSmall : AppTextStyles.labelMedium)
            .copyWith(
          color: onWallpaper ? Colors.white : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FullBadge extends StatelessWidget {
  const _FullBadge({this.small = false, this.onWallpaper = false});
  final bool small;
  final bool onWallpaper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: onWallpaper ? Colors.white.withValues(alpha: 0.22) : AppColors.statusFull,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'FULL',
        style: (small ? AppTextStyles.labelSmall : AppTextStyles.labelMedium)
            .copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  const _SkillBadge({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipUnselected,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level[0].toUpperCase() + level.substring(1),
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m away';
  }
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away';
}
