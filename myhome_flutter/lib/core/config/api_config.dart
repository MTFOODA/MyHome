import 'package:flutter/foundation.dart';

class ApiConfig {
  static String resolveWebBase(String value, Uri origin) =>
      value.startsWith('/') ? origin.resolve(value).toString() : value;

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      // A shared HTTPS gateway serves Flutter and /api/v1 on the same origin.
      if (kIsWeb) return resolveWebBase(override, Uri.base);
      return override;
    }
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return 'http://$host:3000/api/v1';
  }
}
