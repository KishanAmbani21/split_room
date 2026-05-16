import 'package:flutter/material.dart';

import '../../shared/models/app_user.dart';
import 'screens/create_group_screen.dart';

Future<bool?> openCreateGroupScreen(BuildContext context, AppUser creator) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => CreateGroupScreen(creator: creator),
    ),
  );
}
