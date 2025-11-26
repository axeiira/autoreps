import 'package:flutter/material.dart';
import 'package:flutter_autoreps/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_autoreps/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_autoreps/features/home/presentation/pages/home.dart';
import 'package:flutter_autoreps/features/user_plan/presentation/user_plan.dart';
import 'package:flutter_autoreps/features/record/presentation/cam.dart';
import 'package:flutter_autoreps/features/statistics/presentation/pages/main_stats_page.dart';
import 'package:flutter_autoreps/features/settings/presentation/settings.dart';
import 'package:flutter_autoreps/features/history/presentation/history.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case HomePage.routeName:
      case '/':
        return _buildNoAnimationRoute(const HomePage(), settings);
      case LoginPage.routeName:
        return MaterialPageRoute(builder: (_) => const LoginPage(), settings: settings);
      case RegisterPage.routeName:
        return MaterialPageRoute(builder: (_) => const RegisterPage(), settings: settings);
      case UserPlanPage.routeName:
        return MaterialPageRoute(builder: (_) => const UserPlanPage(), settings: settings);
      case CameraPage.routeName:
        return MaterialPageRoute(builder: (_) => const CameraPage(), settings: settings);
      case MainStatsPage.routeName:
        return _buildNoAnimationRoute(const MainStatsPage(), settings);
      case SettingsPage.routeName:
        return _buildNoAnimationRoute(const SettingsPage(), settings);
      case HistoryPage.routeName:
        return _buildNoAnimationRoute(const HistoryPage(), settings);
      default:
        // Fallback to login page for unknown routes
        return MaterialPageRoute(builder: (_) => const LoginPage(), settings: settings);
    }
  }

  static Route<dynamic> _buildNoAnimationRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
