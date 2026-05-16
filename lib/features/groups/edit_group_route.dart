import 'package:flutter/material.dart';

import '../../shared/models/app_user.dart';
import 'screens/edit_group_screen.dart';

Future<bool?> openEditGroupScreen(
  BuildContext context, {
  required AppUser user,
  required String groupId,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => EditGroupScreen(user: user, groupId: groupId),
    ),
  );
}
