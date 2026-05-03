import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The root shell that wraps all main tabs with a branded
/// [NavigationBar] (Material 3).
class HomeScaffold extends ConsumerStatefulWidget {
  const HomeScaffold({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    // Establish socket connection when the authenticated shell mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _socketService = ref.read(socketServiceProvider);
      _socketService?.connect();
    });
  }

  @override
  void dispose() {
    // Do not use ref in dispose — widget may already be unmounted (e.g. session-expired redirect)
    _socketService?.disconnect();
    super.dispose();
  }

  static const _tabs = [
    _TabItem(
      label: AppStrings.navHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: '/home',
    ),
    _TabItem(
      label: AppStrings.navGames,
      icon: Icons.sports_outlined,
      selectedIcon: Icons.sports_rounded,
      route: '/games',
    ),
    _TabItem(
      label: AppStrings.navChat,
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      route: '/chats',
    ),
    _TabItem(
      label: AppStrings.navPerformance,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      route: '/performance',
    ),
    _TabItem(
      label: AppStrings.navProfile,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: '/profile',
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.route));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _BrandedNavBar(
        tabs: _tabs,
        selectedIndex: selectedIndex,
        onTap: (i) => context.go(_tabs[i].route),
      ),
    );
  }
}

// ── Branded nav bar ───────────────────────────────────────────────────────────
class _BrandedNavBar extends StatelessWidget {
  const _BrandedNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.grey200)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              tabs.length,
              (i) => Expanded(
                child: _NavItem(
                  tab: tabs[i],
                  selected: selectedIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Icon(
                selected ? tab.selectedIcon : tab.icon,
                key: ValueKey(selected),
                color: selected ? AppColors.primary : AppColors.grey500,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.primary : AppColors.grey500,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
