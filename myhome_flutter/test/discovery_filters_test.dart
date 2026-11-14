import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'widget_test.dart' show launch;

void main() {
  testWidgets(
    'filter draft applies only after Apply and dismissal preserves applied filters',
    (tester) async {
      final properties = FakePropertyRepository();
      await launch(tester, FakeAuthRepository(), properties: properties);
      expect(properties.searches.length, 1);
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('filter-type-shared_rental')),
      );
      await tester.tap(find.byKey(const ValueKey('filter-type-shared_rental')));
      await tester.pumpAndSettle();
      expect(properties.searches.length, 1);
      await tester.tap(find.byKey(const Key('closeFilters')));
      await tester.pumpAndSettle();
      expect(properties.searches.last.containsKey('category'), false);
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('filter-type-private_rental')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyFilters')));
      await tester.pumpAndSettle();
      expect(properties.searches.last['category'], 'private_rental');
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resetFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('closeFilters')));
      await tester.pumpAndSettle();
      expect(properties.searches.last['category'], 'private_rental');
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resetFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyFilters')));
      await tester.pumpAndSettle();
      expect(properties.searches.last, isEmpty);
    },
  );
  testWidgets(
    'search field submits text and clear removes it from server query',
    (tester) async {
      final properties = FakePropertyRepository();
      await launch(tester, FakeAuthRepository(), properties: properties);
      await tester.enterText(
        find.byKey(const Key('propertySearch')),
        'المعادي',
      );
      expect(properties.searches.length, 1);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(properties.searches.last['q'], 'المعادي');
      await tester.tap(find.byKey(const Key('clearSearch')));
      await tester.pumpAndSettle();
      expect(properties.searches.last.containsKey('q'), false);
    },
  );
  testWidgets(
    'price section validates ranges and normalizes Arabic digits before applying',
    (tester) async {
      final properties = FakePropertyRepository();
      await launch(tester, FakeAuthRepository(), properties: properties);
      await tester.tap(find.byKey(const Key('openFilters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Price and space'));
      await tester.tap(find.text('Price and space'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('filter-minPrice')));
      await tester.enterText(
        find.byKey(const ValueKey('filter-minPrice')),
        '١٠٠٠',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('filter-maxPrice')));
      await tester.enterText(
        find.byKey(const ValueKey('filter-maxPrice')),
        '٥٠٠',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyFilters')));
      await tester.pumpAndSettle();
      expect(find.text('Check the values you entered.'), findsOneWidget);
      expect(properties.searches.length, 1);
      await tester.ensureVisible(find.byKey(const ValueKey('filter-maxPrice')));
      await tester.enterText(
        find.byKey(const ValueKey('filter-maxPrice')),
        '٢٥٠٠',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('applyFilters')));
      await tester.pumpAndSettle();
      expect(properties.searches.last['min_price'], '1000');
      expect(properties.searches.last['max_price'], '2500');
    },
  );
}
