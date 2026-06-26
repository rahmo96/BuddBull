import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/utils/sport_wallpaper_utils.dart';
import 'package:flutter/material.dart';

/// Sport wallpaper with a dark gradient so foreground text stays readable.
class GameSportWallpaper extends StatelessWidget {
  const GameSportWallpaper({
    super.key,
    required this.sport,
    required this.child,
    this.height = 96,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.all(16),
    this.expand = false,
  });

  final String sport;
  final Widget child;
  final double? height;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final wallpaper = SportWallpaperUtils.assetPathForSport(sport);
    final fallbackColor = _sportColor(sport);

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        if (wallpaper != null)
          Image.asset(
            wallpaper,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(color: fallbackColor),
          )
        else
          ColoredBox(color: fallbackColor),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    );

    if (expand) {
      return stack;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: stack,
      ),
    );
  }
}

Color _sportColor(String sport) {
  return switch (sport.toLowerCase()) {
    'football' || 'soccer' => AppColors.footballBadge,
    'basketball' => AppColors.basketballBadge,
    'tennis' => AppColors.tennisBadge,
    'running' => AppColors.runningBadge,
    _ => AppColors.defaultBadge,
  };
}
