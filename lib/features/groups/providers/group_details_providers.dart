import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../models/group_details_data.dart';
import '../services/group_details_service.dart';

final groupDetailsServiceProvider = Provider<GroupDetailsService>(
  (ref) => GroupDetailsService(
    client: ref.watch(supabaseClientProvider),
    realtime: ref.watch(supabaseRealtimeServiceProvider),
  ),
);

final groupDetailsStreamProvider = StreamProvider.autoDispose
    .family<GroupDetailsData, ({String groupId, String userId})>((ref, params) {
  return ref.watch(groupDetailsServiceProvider).watchGroupDetails(
        groupId: params.groupId,
        currentUserId: params.userId,
      );
});
