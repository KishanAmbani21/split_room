import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends push notifications via Supabase Edge Function `send-fcm`.
class FcmPushService {
  FcmPushService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final targets = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (targets.isEmpty) return;

    try {
      final response = await _client.functions.invoke(
        'send-fcm',
        body: {
          'user_ids': targets,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      final details = response.data;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error']);
      }
    } catch (_) {
      // Push is best-effort; in-app notifications still work via Realtime.
    }
  }
}
