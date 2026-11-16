class Account {
  final String id, name, email, role;
  final String? username;
  final bool ownerVerified;
  final List<String> intents;
  final String? activeIntent;
  final String? staffRole;
  final String housingPersona;
  final bool onboardingComplete;
  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.ownerVerified,
    this.username,
    this.intents = const [],
    this.activeIntent,
    this.staffRole,
    this.housingPersona = 'regular',
    this.onboardingComplete = true,
  });
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    username: json['username'] as String?,
    ownerVerified: json['ownerVerified'] as bool,
    intents: List<String>.from(json['intents'] as List? ?? []),
    activeIntent: json['activeIntent'] as String?,
    staffRole: json['staffRole'] as String?,
    housingPersona: json['housingPersona'] as String? ?? 'regular',
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
  );
  bool get canFindRoommates =>
      role != 'admin' &&
      activeIntent == 'tenant_shared' &&
      intents.contains('tenant_shared');
  bool get canManageProperties =>
      role != 'admin' && intents.any((value) => value.startsWith('owner_'));
}

enum AuthFailure {
  credentials,
  emailInUse,
  network,
  rateLimited,
  validation,
  storage,
  server,
}

class AuthException implements Exception {
  final AuthFailure failure;
  const AuthException(this.failure);
}

class PasswordChangeFailure implements Exception {
  final String code;
  const PasswordChangeFailure(this.code);
}

abstract class AuthRepository {
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<Account?> restore();
  Future<Account> login(String email, String password);
  Future<Account> register(
    String name,
    String email,
    String password,
    String role,
  );
  Future<Account> profile();
  Future<void> logout();
  Future<Account> updateIntents(
    List<String> intents,
    String activeIntent,
    String persona,
  );
}
