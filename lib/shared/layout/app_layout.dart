import 'package:flutter/material.dart';

/// Shared responsive layout helpers for consistent spacing across screens.
abstract final class AppLayout {
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static EdgeInsets pagePadding(BuildContext context) {
    final w = screenWidth(context);
    final horizontal = w >= 600 ? 24.0 : 16.0;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16 + bottom);
  }

  static double contentMaxWidth(BuildContext context) {
    final w = screenWidth(context);
    if (w >= 900) return 720;
    if (w >= 600) return 600;
    return double.infinity;
  }

  static double bottomNavClearance(BuildContext context) => 100;

  static EdgeInsets scrollPadding(BuildContext context) {
    final base = pagePadding(context);
    return base.copyWith(
      bottom: base.bottom + bottomNavClearance(context),
    );
  }

  static bool isCompact(BuildContext context) => screenWidth(context) < 360;

  static bool isWide(BuildContext context) => screenWidth(context) >= 600;
}
