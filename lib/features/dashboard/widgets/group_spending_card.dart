import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/group_overview.dart';

class GroupSpendingCard extends StatelessWidget {
  const GroupSpendingCard({
    required this.group,
    super.key,
    this.onTap,
  });

  final GroupOverview group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final balance = group.yourBalance;
    final balanceColor = balance >= 0 ? AppColors.mint : AppColors.coral;
    final balanceLabel =
        balance >= 0 ? 'You will receive' : 'Need to pay';
    final hasImage =
        group.groupImage.isNotEmpty && File(group.groupImage).existsSync();

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.glassFill(brightness),
            AppColors.blue.withValues(alpha: brightness == Brightness.dark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder(brightness)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow(brightness),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.purple],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              backgroundImage:
                  hasImage ? FileImage(File(group.groupImage)) : null,
              child: hasImage
                  ? null
                  : Text(
                      group.groupName.isNotEmpty
                          ? group.groupName[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.groupName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.memberCount} members · ${AppColors.currencySymbol}${group.totalExpense.toStringAsFixed(0)} spent',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brightness == Brightness.dark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balanceLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: balanceColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${AppColors.currencySymbol}${balance.abs().toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}
