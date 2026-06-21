import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global "+" FAB shown on all main tabs. Opens an overlay menu to add a game
/// or log a training session.
class GlobalAddFab extends StatefulWidget {
  const GlobalAddFab({super.key});

  @override
  State<GlobalAddFab> createState() => _GlobalAddFabState();
}

class _GlobalAddFabState extends State<GlobalAddFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _menuFade;
  late final Animation<Offset> _menuSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _rotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _menuFade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_expanded) return;
    setState(() => _expanded = false);
    _controller.reverse();
  }

  void _navigate(String route) {
    _close();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = HomeScaffold.navBottomInset(context) + 8;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_expanded) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: bottom + 64,
            child: FadeTransition(
              opacity: _menuFade,
              child: SlideTransition(
                position: _menuSlide,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuAction(
                        icon: Icons.sports_rounded,
                        label: 'Add Game',
                        onTap: () => _navigate(Routes.createGame),
                      ),
                      const SizedBox(height: 10),
                      _MenuAction(
                        icon: Icons.fitness_center_rounded,
                        label: 'Log Training',
                        onTap: () => _navigate(Routes.createLog),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        Positioned(
          right: 16,
          bottom: bottom,
          child: RotationTransition(
            turns: _rotation,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: AppColors.slate,
              foregroundColor: Colors.white,
              elevation: _expanded ? 8 : 4,
              child: Icon(_expanded ? Icons.close_rounded : Icons.add_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.slate, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
