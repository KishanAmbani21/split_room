import 'package:flutter/foundation.dart';

/// Debug-only helper to trace Firestore writes during development.
abstract final class FirestoreWriteLogger {
  static int _writeCount = 0;

  static int get writeCount => _writeCount;

  static void log(
    String operation, {
    required String collection,
    String? documentId,
    String? reason,
  }) {
    if (!kDebugMode) return;
    _writeCount++;
    final doc = documentId != null ? '/$documentId' : '';
    final why = reason != null ? ' — $reason' : '';
    debugPrint(
      '[Firestore WRITE #$_writeCount] $operation '
      '$collection$doc$why',
    );
  }

  @visibleForTesting
  static void resetCount() => _writeCount = 0;
}
