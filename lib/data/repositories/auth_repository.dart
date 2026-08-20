import 'package:firebase_auth/firebase_auth.dart';

/// Human-readable auth failure the UI can show directly.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper around Firebase Authentication (email + password).
///
/// Everything above this class talks in terms of [AppUser] and [AuthException],
/// so the blocs and widgets never import `firebase_auth` directly.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits on login, logout and app start. Firebase persists the session to
  /// disk itself, so a returning user is restored here without extra storage.
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(credential.user);
      if (user == null) throw const AuthException('Could not sign you in.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      final user = _mapUser(_auth.currentUser);
      if (user == null) throw const AuthException('Could not create account.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  /// Firebase error codes are not shippable copy — translate them.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
        return 'No account found for this email. Try signing up.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try logging in.';
      case 'weak-password':
        return 'Please choose a password of at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and retry.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and retry.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this Firebase project.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

/// The slice of the Firebase user this app actually needs.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final String email;
  final String displayName;

  /// Falls back to the email handle when the profile has no name on it.
  String get greetingName {
    if (displayName.trim().isNotEmpty) return displayName.split(' ').first;
    if (email.contains('@')) return email.split('@').first;
    return 'there';
  }
}
