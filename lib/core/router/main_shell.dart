import 'package:flutter/material.dart';

import '../../features/tasks/presentation/pages/dashboard_page.dart';
import '../../features/tasks/presentation/pages/task_list_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';

// NEW: Global Notifier to trigger tab switches from anywhere
final ValueNotifier<int> globalTabNotifier = ValueNotifier(2);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late PageController _pageController;
  int _selectedIndex = globalTabNotifier.value;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // NEW: Listen for external commands to switch tabs
    globalTabNotifier.addListener(_onGlobalTabChanged);
  }

  @override
  void dispose() {
    globalTabNotifier.removeListener(_onGlobalTabChanged);
    _pageController.dispose();
    super.dispose();
  }

  // Safe handler that avoids infinite animation loops
  void _onGlobalTabChanged() {
    final newIndex = globalTabNotifier.value;
    if (_selectedIndex != newIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuint,
      );
    }
  }

  void _onItemTapped(int index) {
    // Updating the global notifier triggers the listener to do the animation
    globalTabNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = _selectedIndex == 2;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;

        int targetIndex = 2;
        if (_selectedIndex == 0) {
          targetIndex = 1;
        } else if (_selectedIndex == 1) {
          targetIndex = 2;
        } else if (_selectedIndex == 4) {
          targetIndex = 3;
        } else if (_selectedIndex == 3) {
          targetIndex = 2;
        }

        _onItemTapped(targetIndex);
      },
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: const [
            _KeepAlivePage(child: SchedulePage()),
            _KeepAlivePage(child: TaskListPage()),
            _KeepAlivePage(child: DashboardPage()),
            _KeepAlivePage(child: JournalPage()),
            _KeepAlivePage(child: CalendarPage()),
          ],
        ),
        bottomNavigationBar: _FloatingNavBar(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ... The rest of the file stays exactly the same (_KeepAlivePage, _FloatingNavBar, etc.)
// EDGE CASE FIX: Prevents your lists from refreshing and losing scroll position when swiped
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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

    // Updated to match your exact requested order
    final items = [
      _NavItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule),
      _NavItem(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle),
      _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
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
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  horizontal: 20.0,
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