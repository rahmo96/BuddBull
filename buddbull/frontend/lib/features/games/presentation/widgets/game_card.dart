import 'package:flutter/material.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';

/// A rich game card used in the games list and home screen.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.compact = false,
  });

  final GameModel game;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: compact ? _CompactContent(game: game) : _FullContent(game: game),
      ),
    );
  }
}

// ── Full card ─────────────────────────────────────────────────────────────────
class _FullContent extends StatelessWidget {
  const _FullContent({required this.game});
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Coloured sport banner ──────────────────────────────
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: _sportColor(game.sport),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SportIcon(sport: game.sport),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.sport,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _sportColor(game.sport),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: game.status),
                ],
              ),
              const SizedBox(height: 12),

              // ── Date / time / location ──────────────────────────
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                text: '${game.formattedDate} · ${game.formattedTime}',
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: game.location.displayName,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.timer_outlined,
                text: game.formattedDuration,
              ),
              const SizedBox(height: 12),

              // ── Bottom row ─────────────────────────────────────
              Row(
                children: [
                  _SkillBadge(level: game.requiredSkillLevel),
                  const Spacer(),
                  _PlayerSlots(
                    filled: game.approvedCount,
                    total: game.maxPlayers,
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

// ── Compact card (used in horizontal scroll) ──────────────────────────────────
class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.game});
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: _sportColor(game.sport),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SportIcon(sport: game.sport, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        game.sport,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _sportColor(game.sport),
                        ),
                      ),
                    ),
                    _StatusBadge(status: game.status, small: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  game.title,
                  style: AppTextStyles.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${game.formattedDate}\n${game.formattedTime}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                _PlayerSlots(
                  filled: game.approvedCount,
                  total: game.maxPlayers,
                  showLabel: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _SportIcon extends StatelessWidget {
  const _SportIcon({required this.sport, this.size = 36});
  final String sport;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _sportColor(sport).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _sportEmoji(sport),
          style: TextStyle(fontSize: size * 0.55),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.small = false});
  final String status;
  final bool small;

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
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: (small ? AppTextStyles.labelSmall : AppTextStyles.labelMedium)
            .copyWith(
          color: color,
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Text(
        level[0].toUpperCase() + level.substring(1),
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PlayerSlots extends StatelessWidget {
  const _PlayerSlots({
    required this.filled,
    required this.total,
    this.showLabel = true,
  });

  final int filled;
  final int total;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? filled / total : 0.0;
    final color = fraction >= 1
        ? AppColors.statusFull
        : fraction >= 0.75
            ? AppColors.warning
            : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          const Icon(Icons.group_outlined, size: 14, color: AppColors.grey500),
          const SizedBox(width: 4),
        ],
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$filled/$total',
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Sport colour / emoji helpers ─────────────────────────────────────────────
Color _sportColor(String sport) {
  return switch (sport.toLowerCase()) {
    'football' || 'soccer' => AppColors.footballBadge,
    'basketball' => AppColors.basketballBadge,
    'tennis' => AppColors.tennisBadge,
    'running' => AppColors.runningBadge,
    _ => AppColors.defaultBadge,
  };
}

String _sportEmoji(String sport) {
  return switch (sport.toLowerCase()) {
    'football' || 'soccer' => '⚽',
    'basketball' => '🏀',
    'tennis' => '🎾',
    'running' => '🏃',
    'swimming' => '🏊',
    'cycling' => '🚴',
    'volleyball' => '🏐',
    'cricket' => '🏏',
    _ => '🏅',
  };
}
