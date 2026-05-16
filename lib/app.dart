import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/branding/app_branding.dart';
import 'shared/providers/app_providers.dart';
import 'shared/theme/app_theme.dart';

class RoomExpenseApp extends ConsumerWidget {
  const RoomExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashGate(),
    );
  }
}

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(authStateProvider)
        .when(
          data: (user) => user == null
              ? const LoginScreen()
              : DashboardScreen(uid: user.uid),
          error: (error, stackTrace) => const LoginScreen(),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
  }
}
