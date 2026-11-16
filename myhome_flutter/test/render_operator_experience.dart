import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/localizations/app_localizations.dart';
import 'fakes.dart';
import 'fake_property_repository.dart';
import 'operator_features_test.dart' show operatorAccount, DashboardFake;
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
    (language: 'ar', dark: false, size: const Size(390, 900)),
    (language: 'en', dark: true, size: const Size(320, 900)),
  ]) {
    testWidgets('operator experience ${spec.language} ${spec.size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = spec.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'language': spec.language,
        'theme': spec.dark ? 'dark' : 'light',
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('operatorPreview'),
          child: MyHome(
            repository: FakeAuthRepository()..restored = operatorAccount,
            propertyRepository: FakePropertyRepository(),
            salesRepository: DashboardFake(),
            settings: SettingsCubit(await SharedPreferences.getInstance()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String scene) async {
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('operatorPreview')),
          matchesGoldenFile(
            '../../docs/screenshots/operator-$scene-${spec.size.width.toInt()}-${spec.dark ? 'dark' : 'light'}-${spec.language}.png',
          ),
        );
      }

      await capture('intro');
      await tap(tester, find.byKey(const Key('skipIntroduction')));
      await capture('dashboard');
      final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffold.openDrawer();
      await tester.pumpAndSettle();
      await capture('drawer');
      scaffold.closeDrawer();
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('navigation-account')));
      await tap(tester, find.byKey(const Key('changePassword')));
      await capture('password');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      scaffold.openDrawer();
      await tester.pumpAndSettle();
      final guide = AppLocalizations.of(
        tester.element(find.byType(Drawer)),
      )!.guide;
      await tap(
        tester,
        find.descendant(of: find.byType(Drawer), matching: find.text(guide)),
      );
      await capture('guide');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
