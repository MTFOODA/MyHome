import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'package:myhome_flutter/features/support/info_page.dart';
import 'package:myhome_flutter/features/support/introduction_page.dart';
import 'package:myhome_flutter/features/auth/presentation/auth_page.dart';
import 'package:myhome_flutter/features/auth/presentation/auth_cubit.dart';
import 'package:myhome_flutter/core/widgets/architectural_backdrop.dart';
import 'package:myhome_flutter/features/support/guide_content.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'architectural_guides_test.dart' show sceneApp;
import 'fakes.dart';
import 'fake_property_repository.dart';
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
    (language: 'ar', dark: true, size: const Size(390, 900)),
    (language: 'en', dark: false, size: const Size(320, 900)),
  ]) {
    testWidgets('architecture and guides ${spec.language} ${spec.size.width}', (
      tester,
    ) async {
      tester.view.physicalSize = spec.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(Scaffold).first);
        await tester.runAsync(
          () => Future.wait([
            ...ArchitecturalScene.values.map(
              (scene) => precacheImage(AssetImage(scene.asset), context),
            ),
            ...GuidePose.values.map(
              (pose) => precacheImage(AssetImage(pose.asset), context),
            ),
          ]),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('visual47')),
          matchesGoldenFile(
            '../../docs/screenshots/architecture-$name-${spec.size.width.toInt()}-${spec.dark ? 'dark' : 'light'}-${spec.language}.png',
          ),
        );
      }

      Future<void> page(Widget child) async => tester.pumpWidget(
        RepaintBoundary(
          key: const Key('visual47'),
          child: sceneApp(
            child,
            spec.language,
            spec.dark,
            width: spec.size.width,
          ),
        ),
      );
      SharedPreferences.setMockInitialValues({
        'language': spec.language,
        'theme': spec.dark ? 'dark' : 'light',
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('visual47'),
          child: MyHome(
            showIntroduction: false,
            repository: FakeAuthRepository(),
            propertyRepository: FakePropertyRepository()
              ..items = [testProperty],
            settings: SettingsCubit(await SharedPreferences.getInstance()),
          ),
        ),
      );
      await capture('home');
      final auth = AuthCubit(FakeAuthRepository());
      await page(
        BlocProvider.value(
          value: auth,
          child: AuthPage(onGuest: () {}),
        ),
      );
      await capture('login');
      await page(const IntroductionPage());
      await capture('welcome');
      await tap(tester, find.byKey(const Key('nextIntroduction')));
      await capture('list');
      await tap(tester, find.byKey(const Key('nextIntroduction')));
      await capture('connect');
      await page(const InfoPage());
      await capture('guide');
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -450),
      );
      await capture('guide-next');
      await page(const InfoPage(about: true));
      await capture('about');
      await tester.pumpWidget(const SizedBox.shrink());
      await auth.close();
    });
  }
}
