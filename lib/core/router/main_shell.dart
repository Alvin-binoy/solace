import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RouteNames.dashboard)) return 0;
    if (location.startsWith(RouteNames.tasks)) return 1;
    if (location.startsWith(RouteNames.schedule)) return 2;
    if (location.startsWith(RouteNames.journal)) return 3;
    if (location.startsWith(RouteNames.calendar)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
        break;
      case 1:
        context.go(RouteNames.tasks);
        break;
      case 2:
        context.go(RouteNames.schedule);
        break;
      case 3:
        context.go(RouteNames.journal);
        break;
      case 4:
        context.go(RouteNames.calendar);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBackgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFF111111);

    final activePillColor = Colors.white;
    final activeIconColor = Colors.black;
    final inactiveIconColor = Colors.grey.shade500;

    final items = [
      _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
      _NavItem(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle),
      _NavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule),
      _NavItem(icon: Icons.book_outlined, activeIcon: Icons.book),
      _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: navBackgroundColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute evenly since labels are gone
          children: List.generate(items.length, (index) {
            final isSelected = selectedIndex == index;
            final item = items[index];

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutQuint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, // Wider padding to form a pill shape around the single icon
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? activePillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? activeIconColor : inactiveIconColor,
                  size: 24,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;

  _NavItem({
    required this.icon,
    required this.activeIcon,
  });
}