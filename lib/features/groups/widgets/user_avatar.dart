import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/selectable_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.user,
    super.key,
    this.selected = false,
    this.ringColor = AppColors.blue,
    this.radius = 24,
  });

  final SelectableUser user;
  final bool selected;
  final Color ringColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(selected ? 2.5 : 0),
      decoration: selected
          ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [ringColor, ringColor.withValues(alpha: 0.5)],
              ),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.blue.withValues(alpha: 0.12),
        backgroundImage: hasImage ? NetworkImage(user.profileImageUrl!) : null,
        child: hasImage
            ? null
            : Text(
                user.initial,
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.85,
                ),
              ),
      ),
    );
  }
}
