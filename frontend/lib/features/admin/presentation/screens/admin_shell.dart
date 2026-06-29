import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin area shell with section navigation.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _sections = [
    _AdminSection(
      icon: Icons.dashboard_outlined,
      route: Routes.adminDashboard,
    ),
    _AdminSection(
      icon: Icons.people_outline,
      route: Routes.adminUsers,
    ),
    _AdminSection(
      icon: Icons.flag_outlined,
      route: Routes.adminReports,
    ),
    _AdminSection(
      icon: Icons.sports_outlined,
      route: Routes.adminSports,
    ),
    _AdminSection(
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

  String _sectionLabel(BuildContext context, String route) {
    final l10n = context.l10n;
    return switch (route) {
      Routes.adminDashboard => l10n.adminDashboard,
      Routes.adminUsers => l10n.adminUsers,
      Routes.adminReports => l10n.adminReports,
      Routes.adminSports => l10n.adminSports,
      Routes.adminGames => l10n.adminGames,
      _ => route,
    };
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
          title: Text(
            _sectionLabel(context, _sections[selected].route),
            style: AppTextStyles.titleLarge,
          ),
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
                  label: _sectionLabel(context, s.route),
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
    required this.icon,
    required this.route,
  });

  final IconData icon;
  final String route;
}
