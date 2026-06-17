import 'dart:ui';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/services/socket_service.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/chat/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root shell for main tabs with a floating bottom "Dynamic Island" nav pill.
class HomeScaffold extends ConsumerStatefulWidget {
  const HomeScaffold({super.key, required this.child});
  final Widget child;

  static const double islandMargin = 12;
  static const double islandHeight = 52;

  /// Space scrollable content should reserve so the last items clear the pill.
  static double navBottomInset(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom + islandMargin + islandHeight + islandMargin;
  }

  static EdgeInsets scrollPadding(BuildContext context) {
    return EdgeInsets.only(bottom: navBottomInset(context));
  }

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authProvider).status != AuthStatus.authenticated) return;
      _socketService = ref.read(socketServiceProvider);
      _socketService?.connect();
    });
  }

  @override
  void dispose() {
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
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        ref.read(socketServiceProvider).connect();
      }
      if (next.status == AuthStatus.unauthenticated) {
        ref.read(socketServiceProvider).disconnect();
      }
    });

    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _DynamicIslandNavBar(
              tabs: _tabs,
              selectedIndex: selectedIndex,
              onTap: (i) => context.go(_tabs[i].route),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicIslandNavBar extends ConsumerWidget {
  const _DynamicIslandNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadTotal = ref.watch(totalUnreadChatCountProvider);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: HomeScaffold.islandMargin),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          HomeScaffold.islandMargin,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeScaffold.islandHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.slate.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(HomeScaffold.islandHeight / 2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SizedBox(
                height: HomeScaffold.islandHeight,
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (i) => Expanded(
                      child: _NavItem(
                        tab: tabs[i],
                        selected: selectedIndex == i,
                        onTap: () => onTap(i),
                        badgeCount:
                            tabs[i].route == '/chats' ? unreadTotal : 0,
                      ),
                    ),
                  ),
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
    this.badgeCount = 0,
  });

  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Badge(
                  key: ValueKey(selected),
                  isLabelVisible: badgeCount > 0,
                  label: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(fontSize: 9),
                  ),
                  backgroundColor: AppColors.error,
                  child: Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    color: selected ? AppColors.mint : inactiveColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 9,
                  height: 1.1,
                  color: selected ? AppColors.mint : inactiveColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
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
