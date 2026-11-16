import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio dio;
  final FlutterSecureStorage storage;
  String? _accessToken;
  static const _key = 'myhome.refresh.v1';
  ApiAuthRepository(this.dio, this.storage);
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw AuthException(switch (status) {
        401 => AuthFailure.credentials,
        409 => AuthFailure.emailInUse,
        429 => AuthFailure.rateLimited,
        422 => AuthFailure.validation,
        400 => AuthFailure.validation,
        null => AuthFailure.network,
        _ => AuthFailure.server,
      });
    } catch (_) {
      throw const AuthException(AuthFailure.storage);
    }
  }

  Future<Account> _accept(Response<dynamic> response) async {
    final data = Map<String, dynamic>.from(response.data as Map);
    final access = data['accessToken'] as String;
    final account = Account.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    try {
      await storage.write(key: _key, value: data['refreshToken'] as String);
    } catch (_) {
      try {
        await dio.post<dynamic>(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $access'}),
        );
      } catch (_) {}
      throw const AuthException(AuthFailure.storage);
    }
    _accessToken = access;
    return account;
  }

  @override
  Future<Account?> restore() => _call(() async {
    final refresh = await storage.read(key: _key);
    if (refresh == null) return null;
    try {
      return await _accept(
        await dio.post<dynamic>(
          '/auth/refresh',
          data: {'refreshToken': refresh},
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 400) {
        await storage.delete(key: _key);
        _accessToken = null;
        return null;
      }
      rethrow;
    }
  });
  @override
  Future<Account> login(String email, String password) => _call(
    () async => _accept(
      await dio.post<dynamic>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      ),
    ),
  );
  @override
  Future<Account> register(
    String name,
    String email,
    String password,
    String role,
  ) => _call(
    () async => _accept(
      await dio.post<dynamic>(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'role': role,
        },
      ),
    ),
  );
  Future<Response<dynamic>> _authorized(
    String path, {
    bool post = false,
    String? method,
    dynamic data,
    ResponseType responseType = ResponseType.json,
  }) async {
    Future<Response<dynamic>> request() => dio.request<dynamic>(
      path,
      options: Options(
        method: method ?? (post ? 'POST' : 'GET'),
        responseType: responseType,
        receiveTimeout: path == '/identity/scan' || path == '/assets'
            ? const Duration(seconds: 40)
            : null,
        headers: {'Authorization': 'Bearer $_accessToken'},
      ),
      data: data is FormData ? data.clone() : data,
    );
    try {
      return await request();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      if (await restore() == null) {
        throw const AuthException(AuthFailure.credentials);
      }
      return request();
    }
  }

  Future<dynamic> authorizedRequest(
    String path, {
    String method = 'GET',
    dynamic data,
  }) async => (await _authorized(path, method: method, data: data)).data;
  Future<List<int>> authorizedBytes(String path) async => List<int>.from(
    (await _authorized(path, responseType: ResponseType.bytes)).data as List,
  );

  @override
  Future<Account> updateIntents(
    List<String> intents,
    String activeIntent,
    String persona,
  ) => _call(
    () async => Account.fromJson(
      Map<String, dynamic>.from(
        await authorizedRequest(
              '/auth/intents',
              method: 'PUT',
              data: {
                'intents': intents,
                'activeIntent': activeIntent,
                'housingPersona': persona,
              },
            )
            as Map,
      ),
    ),
  );

  @override
  Future<Account> profile() => _call(
    () async => Account.fromJson(
      Map<String, dynamic>.from(
        (await _authorized('/auth/profile')).data as Map,
      ),
    ),
  );
  @override
  Future<void> logout() => _call(() async {
    try {
      await _authorized('/auth/logout', post: true);
    } on AuthException catch (error) {
      if (error.failure != AuthFailure.credentials) rethrow;
    }
    await storage.delete(key: _key);
    _accessToken = null;
  });
}
