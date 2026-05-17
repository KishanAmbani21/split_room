import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../services/activity_undo_service.dart';

final activityUndoServiceProvider = Provider<ActivityUndoService>(
  (ref) => ActivityUndoService(client: ref.watch(supabaseClientProvider)),
);
