import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class ContactsComingSoonTab extends StatelessWidget {
  const ContactsComingSoonTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.12),
            AppColors.coral.withValues(alpha: 0.08),
            AppColors.glassFill(brightness),
          ],
        ),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.15),
                      AppColors.coral.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.contacts_rounded,
                size: 48,
                color: AppColors.purple,
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.coral, AppColors.purple],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Coming Soon',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Contact sync feature will be available soon',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
