import 'package:flutter/material.dart';

/// Minimal premium palette — indigo/violet with restrained accents.
abstract final class AppColors {
  static const currencyCode = 'INR';
  static const currencySymbol = '₹';

  // Semantic (spec)
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);

  // Dark semantic
  static const primaryDark = Color(0xFF818CF8);
  static const secondaryDark = Color(0xFFA78BFA);
  static const successDark = Color(0xFF34D399);
  static const errorDark = Color(0xFFF87171);

  // Legacy aliases (keep imports working across the app)
  static const blue = primary;
  static const blueDeep = Color(0xFF4F46E5);
  static const purple = secondary;
  static const purpleDeep = Color(0xFF7C3AED);
  static const cyan = Color(0xFF06B6D4);
  static const cyanDeep = Color(0xFF0891B2);
  static const mint = success;
  static const mintDeep = Color(0xFF059669);
  static const coral = Color(0xFFF87171);
  static const amber = Color(0xFFF59E0B);
  static const warning = amber;

  // Light surfaces
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightMuted = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);
  static const lightTextMuted = Color(0xFF64748B);

  // Dark surfaces
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkCard = Color(0xFF1E293B);
  static const darkMuted = Color(0xFF334155);
  static const darkBorder = Color(0xFF334155);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextMuted = Color(0xFF94A3B8);

  // Subtle gradients (use sparingly)
  static const primaryGradientLight = [primary, secondary];
  static const primaryGradientDark = [primaryDark, secondaryDark];
  static const createButtonGradientLight = [primary, Color(0xFF7C3AED)];
  static const createButtonGradientDark = [primaryDark, secondaryDark];
  static const backgroundGradientLight = [lightBackground, Color(0xFFF1F5F9)];
  static const backgroundGradientDark = [darkBackground, Color(0xFF111827)];
  static const spentGradientLight = [primary, primary];
  static const spentGradientDark = [primaryDark, primaryDark];
  static const oweGradientLight = [error, error];
  static const oweGradientDark = [errorDark, errorDark];
  static const getBackGradientLight = [success, success];
  static const getBackGradientDark = [successDark, successDark];

  static const chartColors = [
    primary,
    secondary,
    success,
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    error,
  ];

  static const actionBlue = primary;
  static const actionPurple = secondary;
  static const actionMint = success;
  static const actionAmber = amber;

  static Color primaryColor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primary;

  static Color secondaryColor(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryDark : secondary;

  static Color successColor(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : success;

  static Color errorColor(Brightness brightness) =>
      brightness == Brightness.dark ? errorDark : error;

  static List<Color> backgroundGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? backgroundGradientDark
          : backgroundGradientLight;

  static List<Color> createButtonGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? createButtonGradientDark
          : createButtonGradientLight;

  static List<Color> primaryGradient(Brightness brightness) =>
      brightness == Brightness.dark ? primaryGradientDark : primaryGradientLight;

  static Color glassFill(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : lightCard;

  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color cardShadow(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF0F172A).withValues(alpha: 0.06);
}
