import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_update_status.dart';

class AppVersionService {
  const AppVersionService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Future<AppUpdateStatus> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final currentVersion = packageInfo.version;

    try {
      final row = await _client
          .from('app_versions')
          .select(
            'min_supported_build, latest_build, latest_version, '
            'update_message, force_update',
          )
          .eq('platform', defaultTargetPlatform.name)
          .eq('is_active', true)
          .maybeSingle();

      if (row == null) {
        return AppUpdateStatus.available(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
        );
      }

      final minSupportedBuild = _asInt(row['min_supported_build']);
      final forceUpdate = row['force_update'] as bool? ?? false;
      final updateRequired =
          forceUpdate &&
          minSupportedBuild != null &&
          currentBuildNumber < minSupportedBuild;

      return AppUpdateStatus(
        updateRequired: updateRequired,
        message: (row['update_message'] as String?)?.trim().isNotEmpty == true
            ? (row['update_message'] as String).trim()
            : 'A new update is available. Please install the latest build.',
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: row['latest_version'] as String?,
        latestBuildNumber: _asInt(row['latest_build']),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Version check skipped] $error\n$stackTrace');
      }
      return AppUpdateStatus.available(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
      );
    }
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
