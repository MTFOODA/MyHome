import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/config/api_config.dart';

void main() {
  test('public link resolves API against the tester HTTPS origin', () {
    expect(
      ApiConfig.resolveWebBase(
        '/api/v1',
        Uri.parse('https://demo.trycloudflare.com/homes/#/saved'),
      ),
      'https://demo.trycloudflare.com/api/v1',
    );
  });
  test(
    'localhost gateway keeps its port instead of using the direct API port',
    () {
      expect(
        ApiConfig.resolveWebBase(
          '/api/v1',
          Uri.parse('http://localhost:8082/'),
        ),
        'http://localhost:8082/api/v1',
      );
    },
  );
  test('explicit API endpoints remain compatible', () {
    expect(
      ApiConfig.resolveWebBase(
        'https://api.example.com/api/v1',
        Uri.parse('https://demo.trycloudflare.com/'),
      ),
      'https://api.example.com/api/v1',
    );
  });
}
