import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_type.dart';
import '../providers/create_group_provider.dart';
import 'selectable_chip.dart';

class GroupTypeChips extends ConsumerWidget {
  const GroupTypeChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createGroupProvider);
    final notifier = ref.read(createGroupProvider.notifier);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in GroupType.values)
          SelectableChip(
            label: type.label,
            icon: type.icon,
            selected: state.groupType == type,
            accent: SelectableChip.accentFor(type),
            onTap: () => notifier.setGroupType(type),
          ),
      ],
    );
  }
}
