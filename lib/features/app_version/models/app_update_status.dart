class AppUpdateStatus {
  const AppUpdateStatus({
    required this.updateRequired,
    required this.message,
    required this.currentVersion,
    required this.currentBuildNumber,
    this.latestVersion,
    this.latestBuildNumber,
  });

  final bool updateRequired;
  final String message;
  final String currentVersion;
  final int currentBuildNumber;
  final String? latestVersion;
  final int? latestBuildNumber;

  factory AppUpdateStatus.available({
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    return AppUpdateStatus(
      updateRequired: false,
      message: '',
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
    );
  }
}
