import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_page.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_choices.dart';
import 'fakes.dart';
import 'widget_test.dart' show launch;
import 'visual_listing_test.dart' show openListing, nextStep;
import 'onboarding_pricing_test.dart' show tap;

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0, 1920.0]) {
      testWidgets('form and actions scale with viewport $language $width', (
        tester,
      ) async {
        await openListing(tester, language: language, size: Size(width, 1000));
        await tap(
          tester,
          find.byKey(const ValueKey('choice-category-sale_cash')),
        );
        await nextStep(tester);
        final page = find.byType(ListingPage);
        expect(
          find.descendant(of: page, matching: find.byType(Image)),
          findsNothing,
        );
        expect(
          find.descendant(of: page, matching: find.byType(TextFormField)),
          findsNothing,
        );
        expect(
          find.descendant(of: page, matching: find.byType(SwitchListTile)),
          findsNothing,
        );
        for (final entry in {
          'apartment': Icons.apartment_rounded,
          'studio': Icons.weekend_outlined,
          'duplex': Icons.stairs_outlined,
          'villa': Icons.villa_outlined,
          'room': Icons.bed_outlined,
        }.entries) {
          expect(
            find.descendant(
              of: find.byKey(ValueKey('property-kind-${entry.key}')),
              matching: find.byIcon(entry.value),
            ),
            findsOneWidget,
          );
        }
        final action = tester.getSize(find.byKey(const Key('listingContinue')));
        expect(action.height, greaterThanOrEqualTo(width >= 1100 ? 64 : 56));
        expect(action.width, greaterThanOrEqualTo(width >= 1100 ? 250 : 100));
        if (width >= 1100) {
          expect(
            tester.getSize(find.byKey(const Key('listingContent'))).width,
            greaterThan(width * .6),
          );
          final option = tester.getSize(
            find.byKey(const ValueKey('property-kind-apartment')),
          );
          expect(option.height, greaterThanOrEqualTo(112));
        }
        expect(find.byType(ListingChoice), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'language control has a translation glyph and a visible destination language',
    (tester) async {
      await launch(tester, FakeAuthRepository());
      final control = find.byKey(const Key('changeLanguage'));
      expect(
        find.descendant(
          of: control,
          matching: find.byIcon(Icons.translate_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: control, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(of: control, matching: find.text('العربية')),
        findsOneWidget,
      );
      await tap(tester, control);
      expect(
        find.descendant(of: control, matching: find.text('English')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow form keeps readable controls with larger accessibility text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openListing(tester, size: const Size(320, 1000));
      await tap(
        tester,
        find.byKey(const ValueKey('choice-category-sale_cash')),
      );
      await nextStep(tester);
      await tap(tester, find.byKey(const ValueKey('property-kind-studio')));
      expect(tester.takeException(), isNull);
    },
  );
}
