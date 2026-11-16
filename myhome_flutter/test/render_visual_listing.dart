import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myhome_flutter/app/app.dart';
import 'package:myhome_flutter/core/config/settings_cubit.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'onboarding_pricing_test.dart' show tap;
import 'visual_listing_test.dart' show listingOwner, nextStep, completeAddress;

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
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('illustrated listing previews $language dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'language': language,
          'theme': dark ? 'dark' : 'light',
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('listingPreview'),
            child: MyHome(
              showIntroduction: false,
              key: UniqueKey(),
              repository: FakeAuthRepository()..restored = listingOwner,
              propertyRepository: FakePropertyRepository(),
              settings: SettingsCubit(await SharedPreferences.getInstance()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const Key('listingPreview')),
            matchesGoldenFile(
              '../../docs/screenshots/illustrated-$name-${dark ? 'dark-' : ''}$language.png',
            ),
          );
        }

        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await tester.pumpAndSettle();
        await capture('menu');
        await tap(tester, find.byKey(const Key('drawerAddProperty')));
        await capture('category');
        await tap(
          tester,
          find.byKey(const ValueKey('choice-category-sale_cash')),
        );
        await nextStep(tester);
        await tap(
          tester,
          find.byKey(const ValueKey('property-kind-apartment')),
        );
        await capture('details');
        await nextStep(tester);
        await tap(tester, find.byKey(const Key('listingGovernorate')));
        await tap(
          tester,
          find.text(language == 'ar' ? 'القاهرة' : 'Cairo').last,
        );
        await tap(tester, find.byKey(const Key('listingAreaPicker')));
        await tap(tester, find.byKey(const ValueKey('location-option-maadi')));
        await completeAddress(tester);
        await capture('location');
        await nextStep(tester);
        for (final key in [
          'area-115',
          'bedrooms-2',
          'bathrooms-1',
          'choice-area_measurement-net',
        ]) {
          await tap(tester, find.byKey(ValueKey(key)));
        }
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, 1600),
        );
        await tester.pumpAndSettle();
        await capture('dimensions');
        await nextStep(tester);
        await tap(tester, find.byKey(const ValueKey('answer-water-true')));
        await capture('water');
      });
    }
  }
}
