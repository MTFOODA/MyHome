import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/auth/presentation/auth_cubit.dart';
import 'fakes.dart';

void main() {
  test(
    'restores existing session and logout clears the current account',
    () async {
      final repo = FakeAuthRepository()..restored = account;
      final cubit = AuthCubit(repo);
      addTearDown(cubit.close);
      await cubit.restore();
      expect(cubit.state.status, AuthStatus.signedIn);
      expect(cubit.state.account, account);
      await cubit.logout();
      expect(cubit.state.status, AuthStatus.signedOut);
      expect(cubit.state.account, isNull);
    },
  );
  test(
    'network failure on restoration allows retry without discarding session',
    () async {
      final repo = FakeAuthRepository()..failure = AuthFailure.network;
      final cubit = AuthCubit(repo);
      addTearDown(cubit.close);
      await cubit.restore();
      expect(cubit.state.status, AuthStatus.unavailable);
      repo
        ..failure = null
        ..restored = account;
      await cubit.restore();
      expect(cubit.state.account, account);
    },
  );
  test('failed logout keeps the account available for retry', () async {
    final repo = FakeAuthRepository()..restored = account;
    final cubit = AuthCubit(repo);
    addTearDown(cubit.close);
    await cubit.restore();
    repo.failure = AuthFailure.network;
    await cubit.logout();
    expect(cubit.state.account, account);
    expect(cubit.state.failure, AuthFailure.network);
  });
  test(
    'server session rejection clears the account on profile refresh',
    () async {
      final repo = FakeAuthRepository()..restored = account;
      final cubit = AuthCubit(repo);
      addTearDown(cubit.close);
      await cubit.restore();
      repo.failure = AuthFailure.credentials;
      await cubit.refreshProfile();
      expect(cubit.state.account, isNull);
      expect(cubit.state.status, AuthStatus.signedOut);
    },
  );
}
