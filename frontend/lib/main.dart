import 'package:flutter/material.dart';
import 'package:flutter_autoreps/core/theme/app_theme.dart';
import 'package:flutter_autoreps/routes/app_router.dart';
import 'package:flutter_autoreps/features/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autoreps',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.generate,
      initialRoute: LoginPage.routeName,
    );
  }
}
