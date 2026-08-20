part of 'auth_bloc.dart';

enum AuthStatus {
  /// Still waiting for Firebase's first auth-state emission — the splash
  /// screen holds here.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;

  /// True while a sign-in / sign-up request is in flight, so the button can
  /// show a spinner and block double submits.
  final bool isSubmitting;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user?.uid, isSubmitting, errorMessage];
}
