import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../groups/create_group_route.dart';
import '../../../shared/models/app_user.dart';
import 'section_title.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.group_add_rounded,
        label: 'Create Group',
        gradient: const [AppColors.blue, AppColors.cyan],
        onTap: () => openCreateGroupScreen(context, user),
      ),
      _QuickAction(
        icon: Icons.add_card_rounded,
        label: 'Add Expense',
        gradient: const [AppColors.purple, Color(0xFFA78BFA)],
        onTap: () => showAppSnackBar(context, 'Add Expense — coming soon.'),
      ),
      _QuickAction(
        icon: Icons.handshake_rounded,
        label: 'Settle Payment',
        gradient: const [AppColors.mint, AppColors.mintDeep],
        onTap: () => showAppSnackBar(context, 'Settle Payment — coming soon.'),
      ),
      _QuickAction(
        icon: Icons.insights_rounded,
        label: 'View Reports',
        gradient: const [AppColors.amber, Color(0xFFF59E0B)],
        onTap: () => showAppSnackBar(context, 'View Reports — coming soon.'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Quick Actions',
          subtitle: 'Shortcuts to manage your expenses',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth >= 520 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) =>
                  _QuickActionCard(action: actions[index]),
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.gradient.first.withValues(alpha: 0.15),
                action.gradient.last.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: action.gradient.first.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: action.gradient.last.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: action.gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradient.last.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
