import 'package:flutter/material.dart';

import '../../shared/models/app_user.dart';
import 'screens/group_details_screen.dart';

Future<bool?> openGroupDetailsScreen(
  BuildContext context, {
  required AppUser user,
  required String groupId,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => GroupDetailsScreen(user: user, groupId: groupId),
    ),
  );
}
