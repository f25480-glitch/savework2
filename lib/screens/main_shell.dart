import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/work_day_storage.dart';
import 'calendar_screen.dart';
import 'day_detail_screen.dart';
import 'home_screen.dart';
import 'info_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.storage});

  final WorkDayStorage storage;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeScreenState>();
  final _calendarKey = GlobalKey<CalendarScreenState>();

  void _refreshAll() {
    _homeKey.currentState?.refresh();
    _calendarKey.currentState?.refresh();
  }

  Future<void> _openDayDetail(String dateKey) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => DayDetailScreen(
          storage: widget.storage,
          dateKey: dateKey,
          onChanged: _refreshAll,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      AppStrings.menuHome,
      AppStrings.menuCalendar,
      AppStrings.menuInfo,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey, storage: widget.storage),
          CalendarScreen(
            key: _calendarKey,
            storage: widget.storage,
            onOpenDayDetail: _openDayDetail,
          ),
          const InfoScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _homeKey.currentState?.refresh();
          if (index == 1) _calendarKey.currentState?.refresh();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.menuHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: AppStrings.menuCalendar,
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: AppStrings.menuInfo,
          ),
        ],
      ),
    );
  }
}
