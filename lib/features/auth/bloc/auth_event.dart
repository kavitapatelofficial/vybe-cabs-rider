part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Fired once at startup: subscribes to Firebase's auth stream so a session
/// persisted from a previous launch restores automatically.
class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Clears a failure banner when the rider edits the form again.
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

/// Internal — pushed by the Firebase auth-state subscription.
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user?.uid];
}
