import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_event.dart';
import '../../../attendance/presentation/pages/attendance_home_page.dart';
import '../../../attendance/presentation/pages/attendance_stats_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _tabs = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'TRANG CHỦ',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'THỐNG KÊ',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'CÁ NHÂN',
    ),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(const AttendanceLoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _currentIndex == 0
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            AttendanceHomePage(),
            AttendanceStatsPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          tabs: _tabs,
          onTabSelected: (i) {
            if (_currentIndex != i) {
              setState(() => _currentIndex = i);
              HapticFeedback.selectionClick();
            }
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Bottom Navigation Bar Widget
// ──────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> tabs;
  final ValueChanged<int> onTabSelected;

  const _BottomNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFF5900),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin divider at the top
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          // Tabs row – SafeArea only on bottom so icons hug the edge
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: List.generate(
                  tabs.length,
                  (i) => Expanded(
                    child: _NavTabItem(
                      item: tabs[i],
                      isSelected: currentIndex == i,
                      onTap: () => onTabSelected(i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Individual Tab Item
// ──────────────────────────────────────────────────────────
class _NavTabItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Minimal vertical padding so icons sit as low as possible
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated pill indicator above icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 20 : 4,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: color,
              size: 26, // restored original size
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Nav Item Data Model
// ──────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
