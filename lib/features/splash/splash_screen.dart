import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../features/app_version/presentation/update_required_screen.dart';
import '../../shared/branding/app_branding.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/brand_mark.dart';

class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key});

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _openNextScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openNextScreen() async {
    final updateStatus = await ref
        .read(appVersionServiceProvider)
        .checkForUpdate();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => updateStatus.updateRequired
            ? UpdateRequiredScreen(status: updateStatus)
            : const AppEntry(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 88),
              const SizedBox(height: 18),
              Text(
                AppBranding.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppBranding.tagline,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
