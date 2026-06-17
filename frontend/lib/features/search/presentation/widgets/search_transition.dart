import 'dart:ui';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens global search with an expand-from-bar transition.
void openGlobalSearch(BuildContext context, {required Rect origin}) {
  context.push(Routes.search, extra: origin);
}

/// Expands from [originRect] (the home search pill) to fill the screen.
class SearchExpandFromBarTransition extends StatelessWidget {
  const SearchExpandFromBarTransition({
    super.key,
    required this.animation,
    required this.originRect,
    required this.child,
  });

  final Animation<double> animation;
  final Rect? originRect;
  final Widget child;

  static const _hint = 'Search games, players…';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final endRect = Offset.zero & size;
    final begin = originRect ??
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.14),
          width: size.width - 40,
          height: 44,
        );
    final beginRadius = begin.height / 2;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutQuart.transform(animation.value);
        final rect = Rect.lerp(begin, endRect, t)!;
        final radius = lerpDouble(beginRadius, 0, t)!;
        final scrimOpacity = (t * 0.55).clamp(0.0, 0.5);
        final contentOpacity =
            Curves.easeOut.transform(((t - 0.15) / 0.4).clamp(0.0, 1.0));
        final pillOpacity = (1 - (t / 0.22).clamp(0.0, 1.0));
        final bgColor = Color.lerp(
          Colors.white.withValues(alpha: 0.34),
          AppColors.background,
          t,
        )!;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: AppColors.slate.withValues(alpha: scrimOpacity),
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: bgColor),
                    if (pillOpacity > 0.01)
                      Opacity(
                        opacity: pillOpacity,
                        child: _GhostSearchPill(
                          borderRadius: radius,
                          showHint: begin.width > 56,
                        ),
                      ),
                    Opacity(
                      opacity: contentOpacity,
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Glass pill ghost shown at the start of the expand transition.
class _GhostSearchPill extends StatelessWidget {
  const _GhostSearchPill({
    required this.borderRadius,
    required this.showHint,
  });

  final double borderRadius;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: 20,
              ),
              if (showHint) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    SearchExpandFromBarTransition._hint,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Polished search field used on the global search screen header.
class GlobalSearchField extends StatelessWidget {
  const GlobalSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onClear,
    this.showClear = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.grey200.withValues(alpha: 0.9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search games, players…',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDisabled,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.teal,
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: showClear
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}
