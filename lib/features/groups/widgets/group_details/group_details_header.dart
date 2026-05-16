import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../dashboard/widgets/animated_counter.dart';
import '../../models/group_details_data.dart';

class GroupDetailsHeader extends StatelessWidget {
  const GroupDetailsHeader({required this.data, super.key});

  final GroupDetailsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final hasImage =
        data.groupImage.isNotEmpty && File(data.groupImage).existsSync();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.primaryGradientLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              backgroundImage:
                  hasImage ? FileImage(File(data.groupImage)) : null,
              child: hasImage
                  ? null
                  : Text(
                      data.groupName.isNotEmpty
                          ? data.groupName[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.groupName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.memberCount} members · ${AppColors.currencySymbol}${data.totalSpent.toStringAsFixed(0)} total',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalancePill(
                  label: 'Need to Pay',
                  amount: data.youOwe,
                  gradient: brightness == Brightness.dark
                      ? AppColors.oweGradientDark
                      : AppColors.oweGradientLight,
                  icon: Icons.north_east_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalancePill(
                  label: 'You Will Receive',
                  amount: data.youGetBack,
                  gradient: brightness == Brightness.dark
                      ? AppColors.getBackGradientDark
                      : AppColors.getBackGradientLight,
                  icon: Icons.south_west_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.label,
    required this.amount,
    required this.gradient,
    required this.icon,
  });

  final String label;
  final double amount;
  final List<Color> gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedCounter(
            value: amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
