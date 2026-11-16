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
    // Physical phones use the reachable HTTPS server; local development uses an override.
    return kIsWeb
        ? resolveWebBase('/api/v1', Uri.base)
        : 'https://myhome.mohamed-fooda-mtf.workers.dev/api/v1';
  }
}
