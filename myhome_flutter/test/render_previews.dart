import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'fakes.dart';
import 'fake_property_repository.dart';

void main() {
  setUpAll(() async {
    final icons = await File(
      'C:/flutter/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    final bytes = await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });
  for (final language in ['en', 'ar']) {
    testWidgets('updated marketplace preview $language', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      Future<void> launch({Account? restored, bool dark = false}) async {
        SharedPreferences.setMockInitialValues({
          'language': language,
          'theme': dark ? 'dark' : 'light',
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('preview'),
            child: MyHome(
              key: UniqueKey(),
              repository: FakeAuthRepository()..restored = restored,
              propertyRepository: FakePropertyRepository()
                ..items = [testProperty],
              settings: SettingsCubit(await SharedPreferences.getInstance()),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async => expectLater(
        find.byKey(const Key('preview')),
        matchesGoldenFile('../../docs/screenshots/$name-$language.png'),
      );
      await launch();
      await capture('home');
      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();
      await capture('drawer');
      tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await capture('filters');
      await tester.tap(find.byKey(const Key('closeFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await capture('login');
      await tester.ensureVisible(find.byKey(const Key('toggleAuth')));
      await tester.tap(find.byKey(const Key('toggleAuth')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, 1200),
      );
      await tester.pumpAndSettle();
      await capture('register');
      await launch(
        restored: const Account(
          id: 'owner',
          name: 'Mariam',
          email: 'mariam@example.com',
          role: 'owner',
          ownerVerified: false,
          onboardingComplete: false,
        ),
      );
      await capture('roles');
      await launch(
        restored: const Account(
          id: 'owner',
          name: 'Mariam',
          email: 'mariam@example.com',
          role: 'owner',
          ownerVerified: false,
          intents: [
            'owner_sale_cash',
            'owner_private_rental',
            'owner_shared_rental',
          ],
          activeIntent: 'owner_private_rental',
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await capture('listing');
      await launch(dark: true);
      await capture('home-dark');
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await capture('filters-dark');
      await tester.tap(find.byKey(const Key('closeFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await capture('login-dark');
    });
  }
}
