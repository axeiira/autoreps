import 'package:flutter/material.dart';
import 'package:flutter_autoreps/features/home/presentation/pages/home.dart';
import 'package:flutter_autoreps/features/statistics/presentation/pages/main_stats_page.dart';
import 'package:flutter_autoreps/features/settings/presentation/settings.dart';
import 'package:flutter_autoreps/features/history/presentation/history.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppNavBar({super.key, this.currentIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemColor: const Color(0xFFC7F705),
      unselectedItemColor: Colors.white.withOpacity(0.5),
      currentIndex: currentIndex,
      onTap: (index) {
        // allow caller to override navigation
        if (onTap != null) {
          onTap!(index);
          return;
        }

        switch (index) {
          case 0:
            Navigator.pushNamed(context, HomePage.routeName);
            break;
          case 1:
            Navigator.pushNamed(context, HistoryPage.routeName);
            break;
          case 2:
            Navigator.pushNamed(context, MainStatsPage.routeName);
            break;
          case 3:
            Navigator.pushNamed(context, SettingsPage.routeName);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}