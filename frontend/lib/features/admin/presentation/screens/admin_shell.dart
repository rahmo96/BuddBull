import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin area shell with section navigation.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _sections = [
    _AdminSection(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: Routes.adminDashboard,
    ),
    _AdminSection(
      label: 'Users',
      icon: Icons.people_outline,
      route: Routes.adminUsers,
    ),
    _AdminSection(
      label: 'Reports',
      icon: Icons.flag_outlined,
      route: Routes.adminReports,
    ),
    _AdminSection(
      label: 'Sports',
      icon: Icons.sports_outlined,
      route: Routes.adminSports,
    ),
    _AdminSection(
      label: 'Games',
      icon: Icons.event_outlined,
      route: Routes.adminGames,
    ),
  ];

  int _selectedIndex(String location) {
    for (var i = _sections.length - 1; i >= 0; i--) {
      if (location.startsWith(_sections[i].route)) return i;
    }
    return 0;
  }

  void _exitAdmin(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = _selectedIndex(location);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitAdmin(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(_sections[selected].label, style: AppTextStyles.titleLarge),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _exitAdmin(context),
          ),
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => context.go(_sections[i].route),
          destinations: _sections
              .map(
                (s) => NavigationDestination(
                  icon: Icon(s.icon),
                  label: s.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
