import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'admin_accounts_test.dart' show openAdmin, AdminAccountsFake;
import 'onboarding_pricing_test.dart' show tap;

void main() {
  setUpAll(() async {
    for (final entry in {
      'MaterialIcons':
          'C:/flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
    }.entries) {
      final bytes = await File(entry.value).readAsBytes();
      await (FontLoader(
        entry.key,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  for (final spec in [
    (language: 'ar', dark: true, size: const Size(1440, 1000)),
    (language: 'en', dark: false, size: const Size(1440, 1000)),
    (language: 'ar', dark: false, size: const Size(390, 1000)),
    (language: 'en', dark: true, size: const Size(320, 1000)),
  ]) {
    testWidgets('internal accounts ${spec.language} ${spec.size.width}', (
      tester,
    ) async {
      await openAdmin(
        tester,
        AdminAccountsFake(),
        spec.language,
        spec.size,
        dark: spec.dark,
      );
      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('adminPreview')),
          matchesGoldenFile(
            '../../docs/screenshots/accounts-$name-${spec.size.width.toInt()}-${spec.dark ? 'dark' : 'light'}-${spec.language}.png',
          ),
        );
      }

      await capture('team');
      await tap(tester, find.byKey(const Key('createInternalAccount')));
      await capture('roles');
      await tap(
        tester,
        find.byKey(const ValueKey('create-account-document_reviewer')),
      );
      await capture('lawyer');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
