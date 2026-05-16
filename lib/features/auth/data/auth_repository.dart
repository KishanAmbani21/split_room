import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  const AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existingProfile = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (existingProfile.docs.isNotEmpty) {
      throw const AuthException('This email is already registered.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw const AuthException('Signup failed. Please try again.');
    }

    await user.updateDisplayName(fullName.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'full_name': fullName.trim(),
      'email': normalizedEmail,
      'password': 'managed_by_firebase_auth',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'status': 'active',
      'login_type': 'email',
      'device_type': 'android',
    });
  }

  Future<void> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw const AuthException('Login failed. Please try again.');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw const AuthException(
        'Your profile was not found in Firestore. Please contact support.',
      );
    }

    await doc.reference.update({'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> logout() => _auth.signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

String authErrorMessage(Object error) {
  if (error is AuthException) {
    return error.message;
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  if (error is FirebaseException) {
    return error.message ?? 'Firebase request failed.';
  }

  return 'Something went wrong. Please try again.';
}
