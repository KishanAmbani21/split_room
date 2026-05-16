import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class GroupDetailsEmptyState extends StatelessWidget {
  const GroupDetailsEmptyState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue.withValues(alpha: 0.14),
            AppColors.purple.withValues(alpha: 0.1),
            AppColors.glassFill(brightness),
          ],
        ),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          _Illustration(),
          const SizedBox(height: 22),
          Text(
            'No expenses yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message ??
                'Tap "Add Expense" to start tracking shared costs with your group.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withValues(alpha: 0.25),
                  AppColors.purple.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: 4,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
