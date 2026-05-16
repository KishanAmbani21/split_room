import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../models/group_details_data.dart';
import '../services/group_details_service.dart';

export '../models/group_details_data.dart';

final groupDetailsServiceProvider = Provider<GroupDetailsService>(
  (ref) => GroupDetailsService(firestore: ref.watch(firestoreProvider)),
);

typedef GroupDetailsParams = ({String groupId, String userId});

final groupDetailsStreamProvider = StreamProvider.autoDispose
    .family<GroupDetailsData, GroupDetailsParams>((ref, params) {
  return ref.watch(groupDetailsServiceProvider).watchGroupDetails(
        groupId: params.groupId,
        currentUserId: params.userId,
      );
});
