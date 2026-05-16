import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../../features/auth/data/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences must be overridden.'),
);

final themeModeProvider = NotifierProvider<ThemeModeController, bool>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<bool> {
  static const _themeKey = 'is_dark_theme';

  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_themeKey) ?? false;
  }

  void setDarkMode(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_themeKey, value);
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

final userDocumentProvider = StreamProvider.family<AppUser?, String>((
  ref,
  uid,
) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromSnapshot(doc) : null);
});
