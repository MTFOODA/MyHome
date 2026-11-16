import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/input/egyptian_identity.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_cubit.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_location_step.dart';
import 'package:myhome_flutter/core/widgets/choice_artwork.dart';
import 'fakes.dart';
import 'fake_property_repository.dart';
import 'widget_test.dart' show launch;
import 'listing_cubit_test.dart' show fill;
import 'onboarding_pricing_test.dart' show tap;
import 'visual_listing_test.dart' show openListing, nextStep;

void main() {
  test('ID date uses a real calendar and normalizes Arabic/Persian digits', () {
    expect(nationalIdBirthDate('٣٠٠٠٦١٢٠١٠٠٤٩٤'), DateTime(2000, 6, 12));
    expect(nationalIdBirthDate('۳۰۰۰۶۱۲۰۱۰۰۴۹۴'), DateTime(2000, 6, 12));
    expect(nationalIdBirthDate('30002291234567'), DateTime(2000, 2, 29));
    for (final number in [
      '29902291234567',
      '30002301234567',
      '30013011234567',
      '39901011234567',
      '123',
    ]) {
      expect(nationalIdBirthDate(number), isNull);
    }
  });
  test(
    'verification reports each missing item and the exact date mismatch',
    () {
      final cubit = ListingCubit(FakePropertyRepository());
      addTearDown(cubit.close);
      fill(cubit);
      cubit.birthDate = '2001-01-01';
      expect(cubit.valid('verification'), false);
      expect(
        cubit.validationIssue('verification'),
        'NATIONAL_ID_BIRTH_DATE_MISMATCH',
      );
      cubit.birthDate = '2000-01-01';
      cubit.identity = null;
      expect(cubit.validationIssue('verification'), 'needIdentityImage');
      fill(cubit);
      cubit.ownership = null;
      expect(cubit.validationIssue('verification'), 'needOwnershipImage');
      fill(cubit);
      cubit.consent = false;
      expect(cubit.validationIssue('verification'), 'needReviewConsent');
      cubit.values['floor_number'] = -1;
      expect(cubit.validationIssue('location'), 'floorInvalid');
    },
  );
  testWidgets(
    'home categories are compact horizontal picture labels with no results map',
    (tester) async {
      await launch(tester, FakeAuthRepository());
      expect(find.byKey(const Key('changeLanguage')), findsNothing);
      expect(find.byKey(const Key('openSignIn')), findsOneWidget);
      expect(find.byKey(const Key('togglePropertyMap')), findsNothing);
      final category = find.byKey(const ValueKey('quick-type-'));
      expect(tester.getSize(category).height, lessThan(76));
      final picture = find.descendant(
        of: category,
        matching: find.byType(ChoiceArtwork),
      );
      final label = find
          .descendant(of: category, matching: find.byType(Text))
          .last;
      expect(
        (tester.getCenter(picture).dy - tester.getCenter(label).dy).abs(),
        lessThan(2),
      );
    },
  );
  testWidgets('floor is an unsigned numeric input with a ground-floor hint', (
    tester,
  ) async {
    await openListing(tester);
    await tap(tester, find.byKey(const ValueKey('choice-category-sale_cash')));
    await nextStep(tester);
    await tap(tester, find.byKey(const ValueKey('property-kind-apartment')));
    await nextStep(tester);
    expect(find.byType(ListingLocationStep), findsOneWidget);
    final floor = find.byKey(const Key('address-floor_number'));
    await tester.ensureVisible(floor);
    await tester.enterText(floor, '٤');
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: floor, matching: find.byType(TextField)),
          )
          .keyboardType,
      TextInputType.number,
    );
    expect(find.textContaining('0 ='), findsOneWidget);
    await tester.enterText(floor, '-5');
    expect(find.descendant(of: floor, matching: find.text('-5')), findsNothing);
  });
}
