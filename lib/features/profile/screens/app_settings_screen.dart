import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../app_version/widgets/app_version_label.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            value: isDark,
            secondary: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            ),
            title: const Text('Dark theme'),
            onChanged: (value) =>
                ref.read(themeModeProvider.notifier).setDarkMode(value),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('App version'),
            trailing: AppVersionLabel(compact: true),
          ),
        ],
      ),
    );
  }
}
