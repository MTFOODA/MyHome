import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/config/marketplace_strings.dart';
import 'package:myhome_flutter/core/widgets/choice_artwork.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_choices.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_page.dart';
import 'package:myhome_flutter/features/properties/presentation/price_quote_panel.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'onboarding_pricing_test.dart' show CalculatorRepository, calculate, tap;
import 'widget_test.dart' show launch;

const listingOwner = Account(
  id: 'owner',
  name: 'Owner',
  email: 'owner@example.com',
  role: 'user',
  ownerVerified: true,
  intents: [
    'owner_sale_cash',
    'owner_sale_installments',
    'owner_private_rental',
    'owner_shared_rental',
  ],
  activeIntent: 'owner_sale_cash',
);

Future<void> openListing(
  WidgetTester tester, {
  String language = 'en',
  FakePropertyRepository? properties,
  Size size = const Size(390, 900),
}) async {
  await launch(
    tester,
    FakeAuthRepository()..restored = listingOwner,
    language: language,
    size: size,
    properties: properties,
  );
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
  await tap(tester, find.byKey(const Key('drawerAddProperty')));
  expect(find.byType(ListingPage), findsOneWidget);
}

Future<void> nextStep(WidgetTester tester) async {
  await tap(tester, find.byKey(const Key('listingContinue')));
  expect(tester.takeException(), isNull);
}

Future<void> completeAddress(WidgetTester tester) async {
  for (final field in {
    'street_address': 'Test street',
    'building_number': '7',
    'unit_number': '12',
  }.entries) {
    final finder = find.byKey(ValueKey('address-${field.key}'));
    await tester.ensureVisible(finder);
    await tester.enterText(finder, field.value);
  }
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tap(tester, find.byKey(const Key('address-floor_number')));
  await tap(tester, find.text('4').last);
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('illustrated choices fit $language at $width', (
        tester,
      ) async {
        await openListing(tester, language: language, size: Size(width, 1000));
        await tap(
          tester,
          find.byKey(const ValueKey('choice-category-sale_cash')),
        );
        await nextStep(tester);
        await tap(tester, find.byKey(const ValueKey('property-kind-villa')));
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(ChoiceArtwork), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'listing copy is automatic and manual title/description controls are absent',
    (tester) async {
      await openListing(tester);
      await tap(
        tester,
        find.byKey(const ValueKey('choice-category-sale_cash')),
      );
      await nextStep(tester);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.textContaining('Write my own'), findsNothing);
      await nextStep(tester);
      expect(find.text('Choose a property type to continue.'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('property-kind-apartment')));
      await nextStep(tester);
      expect(find.byKey(const Key('listingGovernorate')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['ar', 'en']) {
    for (final category in ['sale_cash', 'shared_rental']) {
      testWidgets(
        'owner completes $category using choices and uploads $language',
        (tester) async {
          final repo = CalculatorRepository();
          await openListing(tester, language: language, properties: repo);
          final context = tester.element(find.byType(ListingPage));
          String label(String key) => words(context, key);
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          const channel = MethodChannel('plugins.flutter.io/file_selector');
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
          Future<void> pick(String key) async {
            final finder = find.byKey(Key(key));
            await tester.ensureVisible(finder);
            await tester.runAsync(() async {
              await tester.tap(finder);
              // File selector bytes are real IO; let them complete outside fake time.
              await Future<void>.delayed(const Duration(milliseconds: 150));
            });
            await tester.pumpAndSettle();
          }

          await tap(tester, find.byKey(ValueKey('choice-category-$category')));
          await nextStep(tester);
          await tap(
            tester,
            find.byKey(const ValueKey('property-kind-apartment')),
          );
          expect(find.byType(TextFormField), findsNothing);
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
          await nextStep(tester);
          await tap(tester, find.byKey(const ValueKey('area-115')));
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .controller!
                .text,
            '115',
          );
          for (final key in [
            'bedrooms-2',
            'bathrooms-1',
            if (category == 'shared_rental') 'capacity-4',
          ]) {
            await tap(tester, find.byKey(ValueKey(key)));
          }
          await tap(
            tester,
            find.byKey(const ValueKey('choice-area_measurement-net')),
          );
          await nextStep(tester);
          for (final field in ['water', 'electricity', 'gas']) {
            await tap(tester, find.byKey(ValueKey('answer-$field-false')));
          }
          await nextStep(tester);
          await tap(
            tester,
            find.byKey(const ValueKey('choice-finishing-plastered')),
          );
          await nextStep(tester);
          await tap(
            tester,
            find.byKey(const ValueKey('answer-elevator-false')),
          );
          await nextStep(tester);
          if (category == 'shared_rental') {
            await tap(tester, find.byKey(const ValueKey('total_beds-3')));
            await tap(tester, find.byKey(const ValueKey('available_beds-2')));
            await nextStep(tester);
          }
          await pick('pickPropertyPhotos');
          await nextStep(tester);
          expect(find.byKey(const Key('listingNationalId')), findsOneWidget);
          await tester.enterText(
            find.byKey(const Key('listingNationalId')),
            '30001011234567',
          );
          await tap(tester, find.byKey(const Key('chooseBirthDate')));
          final ok = MaterialLocalizations.of(
            tester.element(find.byType(DatePickerDialog)),
          ).okButtonLabel;
          await tap(tester, find.text(ok));
          await pick('pickIdentity');
          await pick('pickOwnership');
          await tap(tester, find.byKey(const Key('listingConsent')));
          await nextStep(tester);
          expect(find.byType(PriceQuotePanel), findsNothing);
          expect(find.text(label('propertyReview')), findsOneWidget);
          await nextStep(tester);
          if (category == 'shared_rental') {
            await tap(tester, find.byKey(const Key('pricing-period')));
            await tap(tester, find.text(label('one_year')).last);
          }
          final price = category == 'shared_rental' ? 3000 : 2000000;
          await tap(tester, find.byKey(ValueKey('preset-price-$price')));
          await tap(
            tester,
            find.byKey(const ValueKey('pricing-negotiable-false')),
          );
          if (category == 'shared_rental') {
            await tap(tester, find.byKey(const ValueKey('preset-deposit-0')));
          }
          await calculate(tester);
          await nextStep(tester);
          expect(repo.createCalls, 1);
          final data = repo.submittedPayload!;
          expect(data['category'], category);
          expect(
            (data['title'] as String).contains(
              language == 'ar' ? 'المعادي' : 'Maadi',
            ),
            isTrue,
          );
          expect(
            (data['description'] as String).length,
            greaterThanOrEqualTo(20),
          );
          expect(data['approximate_location'], contains('7 Test street'));
          expect(data['water'], false);
          expect(data['bedrooms'], 2);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'seeker and guest do not get the owner-only Add property shortcut',
    (tester) async {
      for (final account in <Account?>[
        null,
        const Account(
          id: 'buyer',
          name: 'Buyer',
          email: 'buyer@example.com',
          role: 'user',
          ownerVerified: false,
          intents: ['buyer_cash'],
          activeIntent: 'buyer_cash',
        ),
      ]) {
        await launch(tester, FakeAuthRepository()..restored = account);
        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('drawerAddProperty')), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
  testWidgets(
    'number wheel selects an exact value without a keyboard, including zero',
    (tester) async {
      await openListing(tester);
      await tap(
        tester,
        find.byKey(const ValueKey('choice-category-sale_cash')),
      );
      await nextStep(tester);
      await tap(tester, find.byKey(const ValueKey('property-kind-studio')));
      await nextStep(tester);
      // The reusable selector handles exact values outside quick presets.
      int? number;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, set) => ListingQuantity(
                field: 'bedrooms',
                value: number,
                minimum: 0,
                onChanged: (n) => set(() => number = n),
              ),
            ),
          ),
        ),
      );
      await tap(tester, find.byKey(const ValueKey('choose-bedrooms')));
      await tap(tester, find.byType(FilledButton));
      expect(number, 0);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
