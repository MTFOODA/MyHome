import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_page.dart';
import 'package:myhome_flutter/core/widgets/choice_artwork.dart';
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
          find.descendant(of: page, matching: find.byType(ChoiceArtwork)),
          findsNWidgets(5),
        );
        expect(
          find.descendant(of: page, matching: find.byType(TextFormField)),
          findsNothing,
        );
        expect(
          find.descendant(of: page, matching: find.byType(SwitchListTile)),
          findsNothing,
        );
        final cells = <int?>{};
        for (final kind in ['apartment', 'studio', 'duplex', 'villa', 'room']) {
          final artwork = tester.widget<ChoiceArtwork>(
            find.descendant(
              of: find.byKey(ValueKey('property-kind-$kind')),
              matching: find.byType(ChoiceArtwork),
            ),
          );
          cells.add(ChoiceArtwork.cellFor(artwork.name));
        }
        expect(cells.length, 5);
        expect(cells.contains(null), false);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
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
    'language control appears only in profile and changes the destination language',
    (tester) async {
      await launch(tester, FakeAuthRepository());
      expect(find.byKey(const Key('changeLanguage')), findsNothing);
      expect(find.byKey(const Key('openSignIn')), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('navigation-account')));
      final control = find.byKey(const Key('changeLanguage'));
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byIcon(Icons.language_rounded),
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
