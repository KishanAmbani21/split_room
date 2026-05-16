import 'package:flutter/material.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../groups/widgets/group_list_card.dart';
import '../models/dashboard_data.dart';
import 'dashboard_empty_state.dart';
import 'section_title.dart';

class RecentGroupsSection extends StatelessWidget {
  const RecentGroupsSection({
    required this.data,
    required this.user,
    super.key,
  });

  final DashboardData data;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final groups = data.groups.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Recent groups'),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          DashboardEmptyState(
            icon: Icons.groups_outlined,
            title: 'No groups yet',
            subtitle: 'Create a group from the Groups tab to get started.',
            accent: AppColors.primaryColor(Theme.of(context).brightness),
          )
        else
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GroupListCard(group: group, user: user),
            ),
          ),
      ],
    );
  }
}
