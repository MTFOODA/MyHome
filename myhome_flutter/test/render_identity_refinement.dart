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
  for (final preview in [
    (language: 'ar', dark: true, size: const Size(1440, 1000)),
    (language: 'en', dark: false, size: const Size(1920, 1080)),
    (language: 'ar', dark: false, size: const Size(390, 1100)),
    (language: 'en', dark: true, size: const Size(320, 1100)),
  ]) {
    final language = preview.language, dark = preview.dark;
    {
      testWidgets(
        'identity and home refinements $language dark=$dark width=${preview.size.width}',
        (tester) async {
          tester.view.physicalSize = preview.size;
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
                propertyRepository: FakePropertyRepository()
                  ..items = [testProperty],
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
                '../../docs/screenshots/refined-$name-${preview.size.width.toInt()}-${dark ? 'dark' : 'light'}-$language.png',
              ),
            );
          }

          await capture('home');
          await tap(tester, find.byKey(const ValueKey('navigation-account')));
          await tester.ensureVisible(find.byKey(const Key('changeLanguage')));
          await capture('profile');
          await tap(tester, find.byKey(const ValueKey('navigation-home')));
          await tap(tester, find.byKey(const Key('openFilters')));
          await tap(
            tester,
            find.byKey(const ValueKey('filter-section-finishingAndTerms')),
          );
          final finishing = find.byWidgetPredicate(
            (w) =>
                w is DropdownButtonFormField<String> &&
                w.key.toString().contains('filter-finishing:'),
          );
          await tap(tester, finishing);
          await tap(tester, find.text(language == 'ar' ? 'لوكس' : 'Lux').last);
          await tap(
            tester,
            find.byKey(const ValueKey('filter-furnished-false')),
          );
          await capture('filter');
          await tap(tester, find.byKey(const Key('closeFilters')));
          tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
          await tester.pumpAndSettle();

          await tap(tester, find.byKey(const Key('drawerAddProperty')));

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
          await tap(
            tester,
            find.byKey(const ValueKey('location-option-maadi')),
          );
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

          await nextStep(tester);
          await tap(tester, find.byKey(const ValueKey('answer-water-true')));
          for (final field in ['electricity', 'gas']) {
            await tap(tester, find.byKey(ValueKey('answer-$field-false')));
          }
          await nextStep(tester);
          await tap(
            tester,
            find.byKey(const ValueKey('choice-finishing-ultra_super_lux')),
          );
          await tap(
            tester,
            find.byKey(const ValueKey('answer-furnished-true')),
          );
          await capture('furnishing');
          await nextStep(tester);
          await tap(
            tester,
            find.byKey(const ValueKey('answer-elevator-false')),
          );
          await nextStep(tester);
          const channel = MethodChannel('plugins.flutter.io/file_selector');
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'openFile') {
              final path = File('assets/branding/app-icon.png').absolute.path;
              return (call.arguments as Map)['multiple'] == true
                  ? [path, path]
                  : [path];
            }
            return null;
          });
          addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
          final photos = find.byKey(const Key('pickPropertyPhotos'));
          await tester.ensureVisible(photos);
          await tester.runAsync(() async {
            await tester.tap(photos);
            await Future<void>.delayed(const Duration(milliseconds: 200));
          });
          await tester.pumpAndSettle();
          await nextStep(tester);
          expect(find.byKey(const Key('listingNationalId')), findsOneWidget);
          await tester.enterText(
            find.byKey(const Key('listingNationalId')),
            '30001011234567',
          );
          tester.testTextInput.hide();
          await tap(tester, find.byKey(const Key('listingContinue')));
          await capture('verification');
          Future<void> pick(String key) async {
            final finder = find.byKey(Key(key));
            await tester.ensureVisible(finder);
            await tester.runAsync(() async {
              await tester.tap(finder);
              await Future<void>.delayed(const Duration(milliseconds: 150));
            });
            await tester.pumpAndSettle();
          }

          await pick('pickIdentity');
          await pick('pickOwnership');
          await tap(tester, find.byKey(const Key('listingConsent')));
          await tap(tester, find.byKey(const Key('scanIdentity')));
          await capture('scan');
          await nextStep(tester);
          await capture('review');
        },
      );
    }
  }
}
