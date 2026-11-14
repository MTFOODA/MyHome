import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/auth_repository.dart';

enum AuthStatus { restoring, signedOut, busy, signedIn, unavailable }

class AuthState {
  final AuthStatus status;
  final Account? account;
  final AuthFailure? failure;
  const AuthState(this.status, {this.account, this.failure});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  AuthCubit(this.repository) : super(const AuthState(AuthStatus.restoring));
  Future<void> restore() async {
    emit(const AuthState(AuthStatus.restoring));
    try {
      final account = await repository.restore();
      emit(
        AuthState(
          account == null ? AuthStatus.signedOut : AuthStatus.signedIn,
          account: account,
        ),
      );
    } on AuthException catch (error) {
      emit(AuthState(AuthStatus.unavailable, failure: error.failure));
    }
  }

  void continueAsGuest() => emit(const AuthState(AuthStatus.signedOut));
  void clearError() => emit(
    AuthState(
      state.account == null ? AuthStatus.signedOut : AuthStatus.signedIn,
      account: state.account,
    ),
  );
  Future<void> submit({
    required String email,
    required String password,
    String? name,
    String role = 'user',
  }) async {
    if (state.status == AuthStatus.busy) return;
    emit(const AuthState(AuthStatus.busy));
    try {
      final account = name == null
          ? await repository.login(email, password)
          : await repository.register(name, email, password, role);
      emit(AuthState(AuthStatus.signedIn, account: account));
    } on AuthException catch (error) {
      emit(AuthState(AuthStatus.signedOut, failure: error.failure));
    }
  }

  Future<void> refreshProfile() async {
    if (state.status == AuthStatus.busy) return;
    final account = state.account;
    emit(AuthState(AuthStatus.busy, account: account));
    try {
      emit(AuthState(AuthStatus.signedIn, account: await repository.profile()));
    } on AuthException catch (error) {
      emit(
        AuthState(
          error.failure == AuthFailure.credentials
              ? AuthStatus.signedOut
              : AuthStatus.signedIn,
          account: error.failure == AuthFailure.credentials ? null : account,
          failure: error.failure,
        ),
      );
    }
  }

  Future<void> logout() async {
    if (state.status == AuthStatus.busy) return;
    final account = state.account;
    emit(AuthState(AuthStatus.busy, account: account));
    try {
      await repository.logout();
      emit(const AuthState(AuthStatus.signedOut));
    } on AuthException catch (error) {
      emit(
        AuthState(
          AuthStatus.signedIn,
          account: account,
          failure: error.failure,
        ),
      );
    }
  }

  Future<void> updateIntents(
    List<String> intents,
    String activeIntent,
    String persona,
  ) async {
    if (state.status == AuthStatus.busy) return;
    final account = state.account;
    emit(AuthState(AuthStatus.busy, account: account));
    try {
      emit(
        AuthState(
          AuthStatus.signedIn,
          account: await repository.updateIntents(
            intents,
            activeIntent,
            persona,
          ),
        ),
      );
    } on AuthException catch (error) {
      emit(
        AuthState(
          AuthStatus.signedIn,
          account: account,
          failure: error.failure,
        ),
      );
    }
  }
}
