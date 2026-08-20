import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the session for the whole app. Provided above the navigator in
/// `app.dart`, so the splash screen, home screen and profile menu all read the
/// same source of truth.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthErrorCleared>(
      (_, emit) => emit(state.copyWith(clearError: true)),
    );
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _userSubscription;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _userSubscription?.cancel();
    _userSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    var user = event.user;

    // Firebase delivers the auth-state event for a newly created account
    // without a display name, and it can arrive *after* signUp has already
    // supplied the real profile. Don't let that late, nameless event overwrite
    // a name we already hold for the same account, or the rider gets greeted
    // by their email handle until the next sign-in.
    final known = state.user;
    if (user != null &&
        known != null &&
        known.uid == user.uid &&
        user.displayName.trim().isEmpty &&
        known.displayName.trim().isNotEmpty) {
      user = AppUser(
        uid: user.uid,
        email: user.email,
        displayName: known.displayName,
      );
    }

    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
        clearError: true,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      // The auth-state subscription flips the status to authenticated.
    } on AuthException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _authRepository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      // Take the user straight from signUp rather than waiting on the stream.
      // The account is created before the display name is set, so the stream's
      // event carries a profile with no name on it and does not fire again
      // once the name lands — the rider would be greeted by their email handle
      // until the next login. signUp already reloads and returns the real one.
      add(_AuthUserChanged(user));
    } on AuthException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
