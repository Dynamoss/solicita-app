import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';

part 'auth_state.dart';

/// Owns authentication state. Doubles as the source of truth for route
/// protection (the router listens to it and redirects on changes).
///
/// Cubit (not Bloc) is deliberate here: auth transitions are simple imperative
/// commands (checkAuth/login/logout) with no need for an event stream — see the
/// README's "Why bloc / Cubit vs Bloc" note.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required Login login,
    required Logout logout,
    required GetCurrentSession getCurrentSession,
  })  : _login = login,
        _logout = logout,
        _getCurrentSession = getCurrentSession,
        super(const AuthState());

  final Login _login;
  final Logout _logout;
  final GetCurrentSession _getCurrentSession;

  /// Restores any persisted session on startup.
  Future<void> checkAuth() async {
    final result = await _getCurrentSession();
    result.fold(
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
      (session) => emit(
        session == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, session: session),
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.authenticating));
    final result = await _login(LoginParams(email: email, password: password));
    result.fold(
      (failure) => emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        ),
      ),
      (session) => emit(
        AuthState(status: AuthStatus.authenticated, session: session),
      ),
    );
  }

  Future<void> logout() async {
    await _logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
