import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../group_details_route.dart';
import '../../dashboard/models/group_overview.dart';

class GroupListCard extends StatelessWidget {
  const GroupListCard({
    required this.group,
    required this.user,
    super.key,
  });

  final GroupOverview group;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final hasImage =
        group.groupImage.isNotEmpty && File(group.groupImage).existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openGroupDetailsScreen(
          context,
          user: user,
          groupId: group.groupId,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder(brightness)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow(brightness),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    hasImage ? FileImage(File(group.groupImage)) : null,
                child: hasImage
                    ? null
                    : Text(
                        group.groupName.isNotEmpty
                            ? group.groupName[0].toUpperCase()
                            : 'G',
                        style: TextStyle(
                          color: AppColors.primaryColor(brightness),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      icon: Icons.people_outline,
                      text: '${group.memberCount} members',
                      muted: muted,
                    ),
                    const SizedBox(height: 2),
                    _MetaRow(
                      icon: Icons.payments_outlined,
                      text:
                          '${AppColors.currencySymbol}${group.totalExpense.toStringAsFixed(0)} total',
                      muted: muted,
                    ),
                    if (group.lastActivityAt != null) ...[
                      const SizedBox(height: 2),
                      _MetaRow(
                        icon: Icons.history_rounded,
                        text:
                            'Last activity ${_formatRelative(group.lastActivityAt!)}',
                        muted: muted,
                      ),
                    ] else if (group.createdAt != null) ...[
                      const SizedBox(height: 2),
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        text: 'Created ${_formatDate(group.createdAt!)}',
                        muted: muted,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(date);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.muted,
  });

  final IconData icon;
  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
