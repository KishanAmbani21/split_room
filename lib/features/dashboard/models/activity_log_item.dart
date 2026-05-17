enum ActivityType {
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  groupDeleted,
  settlement,
  groupCreated,
  groupUpdated,
  memberJoined,
  memberRemoved,
  activityRestored,
  unknown,
}

class ActivityLogItem {
  const ActivityLogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.amount,
    this.groupName,
    this.groupId,
    this.groupImage,
    this.relatedId,
    this.actorName,
    this.canUndo = false,
    this.isRestored = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final ActivityType type;
  final double? amount;
  final String? groupName;
  final String? groupId;
  final String? groupImage;
  final String? relatedId;
  final String? actorName;
  final bool canUndo;
  final bool isRestored;

  bool get isDeletedAction =>
      type == ActivityType.expenseDeleted ||
      type == ActivityType.groupDeleted ||
      type == ActivityType.memberRemoved;
}

class GroupedActivities {
  const GroupedActivities({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.activities,
  });

  final String groupId;
  final String groupName;
  final String groupImage;
  final List<ActivityLogItem> activities;

  String get introText {
    final count = activities.length;
    if (count == 1) return '1 recent update';
    return '$count recent updates';
  }
}

List<GroupedActivities> groupActivitiesByGroup(List<ActivityLogItem> items) {
  final visible = items.where((a) => !a.isRestored).toList();
  final map = <String, GroupedActivities>{};

  for (final item in visible) {
    final id = item.groupId ?? item.groupName ?? 'unknown';
    final existing = map[id];
    if (existing != null) {
      map[id] = GroupedActivities(
        groupId: existing.groupId,
        groupName: existing.groupName,
        groupImage: existing.groupImage,
        activities: [...existing.activities, item],
      );
    } else {
      map[id] = GroupedActivities(
        groupId: id,
        groupName: item.groupName ?? 'Group',
        groupImage: item.groupImage ?? '',
        activities: [item],
      );
    }
  }

  for (final key in map.keys.toList()) {
    final sorted = List<ActivityLogItem>.from(map[key]!.activities)
      ..sort((a, b) {
        final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    map[key] = GroupedActivities(
      groupId: map[key]!.groupId,
      groupName: map[key]!.groupName,
      groupImage: map[key]!.groupImage,
      activities: sorted,
    );
  }

  final groups = map.values.toList();
  groups.sort((a, b) {
    final at = a.activities.first.timestamp ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b.activities.first.timestamp ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  });
  return groups;
}
