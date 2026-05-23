import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';

class AppVersionLabel extends ConsumerWidget {
  const AppVersionLabel({
    super.key,
    this.compact = false,
    this.textAlign = TextAlign.center,
  });

  final bool compact;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);

    return packageInfo.when(
      data: (info) {
        final versionText = compact
            ? 'v${info.version}+${info.buildNumber}'
            : 'Version ${info.version}+${info.buildNumber}';

        return Text(
          versionText,
          textAlign: textAlign,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        );
      },
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}
