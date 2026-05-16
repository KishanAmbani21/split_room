import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../models/group_details_data.dart';
import '../../models/group_member_balance.dart';
import '../premium_section_header.dart';

class GroupMembersList extends StatelessWidget {
  const GroupMembersList({
    required this.data,
    required this.currentUserId,
    super.key,
  });

  final GroupDetailsData data;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSectionHeader(
          title: 'Members',
          subtitle: 'Balances within this group',
          accent: AppColors.purple,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${data.memberCount}',
              style: const TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...data.members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MemberBalanceTile(
              member: member,
              isYou: member.userId == currentUserId,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberBalanceTile extends StatelessWidget {
  const _MemberBalanceTile({
    required this.member,
    required this.isYou,
  });

  final GroupMemberBalance member;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final balance = member.balance;
    final color = member.receivesMoney
        ? AppColors.mint
        : member.owesMoney
            ? AppColors.coral
            : AppColors.blue;
    final label = member.receivesMoney
        ? 'will receive'
        : member.owesMoney
            ? 'need to pay'
            : 'settled';

    final hasImage = member.profileImage != null &&
        member.profileImage!.isNotEmpty &&
        File(member.profileImage!).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            AppColors.glassFill(brightness),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            backgroundImage:
                hasImage ? FileImage(File(member.profileImage!)) : null,
            child: hasImage
                ? null
                : Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isYou ? '${member.name} (You)' : member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (member.isCreator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brightness == Brightness.dark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            member.isSettled
                ? '—'
                : '${AppColors.currencySymbol}${balance.abs().toStringAsFixed(0)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
