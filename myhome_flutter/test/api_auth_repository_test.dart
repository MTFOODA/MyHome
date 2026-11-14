import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/auth/data/api_auth_repository.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';

class _Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  _Adapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
const user = {
  'id': '123',
  'name': 'Mariam',
  'email': 'mariam@example.com',
  'role': 'owner',
  'ownerVerified': false,
};
const session = {
  'accessToken': 'access',
  'refreshToken': 'next-refresh',
  'user': user,
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const key = 'myhome.refresh.v1';
  late Dio dio;
  late ApiAuthRepository repository;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({key: 'saved-refresh'});
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    repository = ApiAuthRepository(dio, storage);
  });
  tearDown(() => dio.close());
  test(
    'restores using refresh endpoint, rotating the only persisted credential',
    () async {
      dio.httpClientAdapter = _Adapter((options) async {
        expect(options.path, '/auth/refresh');
        expect(options.data, {'refreshToken': 'saved-refresh'});
        return response(session);
      });
      final account = await repository.restore();
      expect(account?.ownerVerified, false);
      expect(await storage.readAll(), {key: 'next-refresh'});
    },
  );
  test(
    'network outage preserves the saved session for a later retry',
    () async {
      dio.httpClientAdapter = _Adapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        repository.restore(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.network,
          ),
        ),
      );
      expect(await storage.read(key: key), 'saved-refresh');
    },
  );
  test(
    'invalid session is removed without treating the user as signed in',
    () async {
      dio.httpClientAdapter = _Adapter(
        (_) async => response({'message': 'INVALID_SESSION'}, 401),
      );
      expect(await repository.restore(), isNull);
      expect(await storage.read(key: key), isNull);
    },
  );
  test(
    'profile retries once after refreshing an expired access token',
    () async {
      var profileRequests = 0;
      dio.httpClientAdapter = _Adapter((options) async {
        if (options.path == '/auth/refresh') return response(session);
        expect(options.path, '/auth/profile');
        if (++profileRequests == 1) return response({}, 401);
        expect(options.headers['Authorization'], 'Bearer access');
        return response(user);
      });
      expect((await repository.profile()).email, 'mariam@example.com');
      expect(profileRequests, 2);
    },
  );
  test(
    'logout calls server revocation before deleting the stored token',
    () async {
      var revoked = false;
      dio.httpClientAdapter = _Adapter((options) async {
        if (options.path == '/auth/refresh') return response(session);
        expect(options.path, '/auth/logout');
        expect(options.method, 'POST');
        expect(await storage.read(key: key), 'next-refresh');
        revoked = true;
        return response({}, 204);
      });
      await repository.restore();
      await repository.logout();
      expect(revoked, true);
      expect(await storage.readAll(), isEmpty);
    },
  );
  test(
    'registration sends the selected role and maps duplicate email errors',
    () async {
      dio.httpClientAdapter = _Adapter((options) async {
        expect(options.data, {
          'name': 'Mariam',
          'email': 'mariam@example.com',
          'password': 'password-123',
          'role': 'student',
        });
        return response({'message': 'EMAIL_IN_USE'}, 409);
      });
      await expectLater(
        repository.register(
          ' Mariam ',
          ' mariam@example.com ',
          'password-123',
          'student',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.emailInUse,
          ),
        ),
      );
    },
  );
}
