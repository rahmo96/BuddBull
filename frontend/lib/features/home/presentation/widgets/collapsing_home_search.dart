import 'dart:ui';

import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SearchBarTapCallback = void Function(Rect origin);

/// Morphing search affordance for the home header.
///
/// At [expandRatio] 1: wide glass pill below the greeting.
/// At [expandRatio] 0: compact search icon beside header actions.
class CollapsingHomeSearch extends StatelessWidget {
  const CollapsingHomeSearch({
    super.key,
    required this.expandRatio,
    required this.onTap,
    this.collapsedTrailing,
  });

  final double expandRatio;
  final SearchBarTapCallback onTap;
  final Widget? collapsedTrailing;

  static const double _iconSize = 40;
  static const double _expandedHeight = 44;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(expandRatio.clamp(0.0, 1.0));
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBarWidth = screenWidth - 40;
    final barWidth = lerpDouble(_iconSize, maxBarWidth, t)!;
    final barHeight = lerpDouble(_iconSize, _expandedHeight, t)!;
    final hintOpacity = t;
    final bgOpacity = lerpDouble(0.22, 0.35, t)!;

    final isExpandedLayout = t > 0.55;

    if (isExpandedLayout) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _SearchGlassPill(
            width: barWidth,
            height: barHeight,
            bgOpacity: bgOpacity,
            hintOpacity: hintOpacity,
            onTap: onTap,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchGlassPill(
                width: barWidth,
                height: barHeight,
                bgOpacity: bgOpacity,
                hintOpacity: hintOpacity,
                onTap: onTap,
              ),
              if (collapsedTrailing != null) collapsedTrailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchGlassPill extends StatefulWidget {
  const _SearchGlassPill({
    required this.width,
    required this.height,
    required this.bgOpacity,
    required this.hintOpacity,
    required this.onTap,
  });

  final double width;
  final double height;
  final double bgOpacity;
  final double hintOpacity;
  final SearchBarTapCallback onTap;

  @override
  State<_SearchGlassPill> createState() => _SearchGlassPillState();
}

class _SearchGlassPillState extends State<_SearchGlassPill>
    with SingleTickerProviderStateMixin {
  static const _hint = 'Search games, players…';

  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;
  final _boundsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _pressCtrl.forward(from: 0).then((_) {
      if (mounted) _pressCtrl.reverse();
    });

    final box = _boundsKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero;
    widget.onTap(origin);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.height / 2),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: ClipRRect(
            key: _boundsKey,
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: widget.bgOpacity),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.92),
                      size: 20,
                    ),
                    if (widget.hintOpacity > 0.15) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Opacity(
                          opacity: widget.hintOpacity,
                          child: Text(
                            _hint,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calendar + notification actions shown beside the collapsed search icon.
class HomeHeaderActions extends StatelessWidget {
  const HomeHeaderActions({
    super.key,
    required this.onCalendarTap,
    required this.notificationBell,
  });

  final VoidCallback onCalendarTap;
  final Widget notificationBell;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          onPressed: onCalendarTap,
          tooltip: 'My calendar',
        ),
        notificationBell,
      ],
    );
  }
}
