import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';

const account = Account(
  id: '1',
  name: 'Mariam Ahmed',
  email: 'mariam@example.com',
  role: 'owner',
  ownerVerified: false,
);

class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}
  Account registeredAccount = account;
  Account? restored;
  AuthFailure? failure;
  int loginCalls = 0, registerCalls = 0;
  String? selectedRole;
  @override
  Future<Account?> restore() async {
    if (failure != null) throw AuthException(failure!);
    return restored;
  }

  @override
  Future<Account> login(String email, String password) async {
    loginCalls++;
    if (failure != null) throw AuthException(failure!);
    return account;
  }

  @override
  Future<Account> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    registerCalls++;
    selectedRole = role;
    if (failure != null) throw AuthException(failure!);
    return registeredAccount;
  }

  @override
  Future<void> logout() async {
    if (failure != null) throw AuthException(failure!);
  }

  @override
  Future<Account> profile() async {
    if (failure != null) throw AuthException(failure!);
    return account;
  }

  @override
  Future<Account> updateIntents(
    List<String> intents,
    String activeIntent,
    String persona,
  ) async => Account(
    id: account.id,
    name: account.name,
    email: account.email,
    role: account.role,
    ownerVerified: false,
    intents: intents,
    activeIntent: activeIntent,
    housingPersona: persona,
    onboardingComplete: true,
  );
}
