import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../models/app_update_status.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({required this.status, super.key});

  final AppUpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final textColor = brightness == Brightness.dark
        ? AppColors.darkText
        : AppColors.lightText;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 88),
                const SizedBox(height: 22),
                Text(
                  status.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
