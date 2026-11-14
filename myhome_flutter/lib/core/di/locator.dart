import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/api_auth_repository.dart';
import '../../features/properties/data/api_property_repository.dart';
import '../../features/properties/domain/property_repository.dart';

final locator = GetIt.instance;
Future<void> setupLocator() async {
  if (locator.isRegistered<AuthRepository>()) return;
  locator.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  final auth = ApiAuthRepository(dio, const FlutterSecureStorage());
  locator.registerSingleton<AuthRepository>(auth);
  locator.registerSingleton<PropertyRepository>(
    ApiPropertyRepository(dio, auth),
  );
}
