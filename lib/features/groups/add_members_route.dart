import 'package:flutter/material.dart';

import '../../shared/models/app_user.dart';
import 'screens/add_members_screen.dart';

Future<bool?> openAddMembersScreen(
  BuildContext context, {
  required AppUser user,
  required String groupId,
  required String groupName,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => AddMembersScreen(
        user: user,
        groupId: groupId,
        groupName: groupName,
      ),
    ),
  );
}
