import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/auth/data/api_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Flutter repository registers, restores, refreshes profile and logs out against local API',
    () async {
      // This opt-in integration test deliberately uses a real local HTTP server.
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousOverrides);
      FlutterSecureStorage.setMockInitialValues({});
      // Host-side tests default to Android's target platform, so use the host URL explicitly.
      const baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:3000/api/v1',
      );
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      addTearDown(dio.close);
      const storage = FlutterSecureStorage();
      final email =
          'flutter-live-${DateTime.now().microsecondsSinceEpoch}@example.com';
      final first = ApiAuthRepository(dio, storage);
      final account = await first.register(
        'Local API Test',
        email,
        'integration-password-123',
        'owner',
      );
      expect(account.ownerVerified, false);
      final refresh = await storage.read(key: 'myhome.refresh.v1');
      expect(refresh, isNotNull);
      // A fresh repository instance represents a restarted application.
      final restarted = ApiAuthRepository(dio, storage);
      expect((await restarted.restore())?.id, account.id);
      expect(await storage.read(key: 'myhome.refresh.v1'), isNot(refresh));
      expect((await restarted.profile()).email, email);
      await restarted.logout();
      expect(await storage.readAll(), isEmpty);
      expect(await ApiAuthRepository(dio, storage).restore(), isNull);
    },
  );
}
