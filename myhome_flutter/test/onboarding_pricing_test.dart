import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/properties/domain/property_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_cubit.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_pricing_step.dart';
import 'package:myhome_flutter/features/properties/presentation/price_quote_panel.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'listing_cubit_test.dart' show fill;
import 'pricing_test_data.dart';
import 'sales_chat_test.dart' show financialApp;
import 'widget_test.dart' show launch;

class CalculatorRepository extends FakePropertyRepository {
  final quotes = <Map<String, dynamic>>[];
  bool fail = false;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? response;
  @override
  Future<Map<String, dynamic>> priceQuote(Map<String, dynamic> values) async {
    quotes.add(Map.of(values));
    if (fail) throw const PropertyException('NETWORK_ERROR');
    if (response != null) return response!(values);
    if (values['category'] == 'shared_rental') return sharedQuote;
    if (values['category'] == 'private_rental') {
      return values['rental_period'] == 'three_years'
          ? rentalThreeQuote
          : rentalQuote;
    }
    return saleQuote;
  }
}

Future<void> calculate(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 1440.0]) {
      testWidgets(
        'first login has two role families without finance $language $width',
        (tester) async {
          await launch(
            tester,
            FakeAuthRepository()
              ..restored = const Account(
                id: 'new',
                name: 'New',
                email: 'new@example.com',
                role: 'user',
                ownerVerified: false,
                onboardingComplete: false,
              ),
            language: language,
            size: Size(width, 900),
          );
          expect(find.byKey(const ValueKey('family_owner')), findsOneWidget);
          expect(find.byKey(const ValueKey('family_seeker')), findsOneWidget);
          expect(find.byType(PriceQuotePanel), findsNothing);
          expect(find.textContaining('1%'), findsNothing);
          expect(
            find.byKey(const ValueKey('intent_owner_sale_cash')),
            findsNothing,
          );
          await tap(tester, find.byKey(const ValueKey('family_owner')));
          await tap(
            tester,
            find.byKey(const ValueKey('intent_owner_sale_cash')),
          );
          expect(
            find.byKey(const ValueKey('intent_tenant_shared')),
            findsNothing,
          );
          expect(
            tester
                .widget<FilledButton>(find.byKey(const Key('saveIntents')))
                .onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'both families need a subtype; removing owner keeps shared housing and its active mode',
    (tester) async {
      await launch(
        tester,
        FakeAuthRepository()
          ..restored = const Account(
            id: 'new',
            name: 'New',
            email: 'new@example.com',
            role: 'user',
            ownerVerified: false,
            onboardingComplete: false,
          ),
      );
      await tap(tester, find.byKey(const ValueKey('family_owner')));
      await tap(tester, find.byKey(const ValueKey('intent_owner_sale_cash')));
      await tap(tester, find.byKey(const ValueKey('family_seeker')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('saveIntents')))
            .onPressed,
        isNull,
      );
      await tap(tester, find.byKey(const ValueKey('intent_tenant_shared')));
      expect(find.text('Housing profile'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('family_owner')));
      expect(
        find.byKey(const ValueKey('intent_owner_sale_cash')),
        findsNothing,
      );
      await tap(tester, find.byKey(const Key('saveIntents')));
      expect(find.text('Find roommates'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'all listing types end with price after verification/review and validate their financial fields',
    () {
      final cubit = ListingCubit(FakePropertyRepository());
      addTearDown(cubit.close);
      fill(cubit);
      for (final category in [
        'sale_cash',
        'sale_installments',
        'private_rental',
        'shared_rental',
      ]) {
        cubit.values['category'] = category;
        expect(cubit.steps.last, 'pricing');
        expect(
          cubit.steps.indexOf('verification'),
          lessThan(cubit.steps.indexOf('pricing')),
        );
        expect(cubit.steps, isNot(contains('rental_period')));
        expect(cubit.steps, isNot(contains('installments')));
      }
      cubit.values['category'] = 'private_rental';
      cubit.values.remove('rental_period');
      expect(cubit.valid('pricing'), isFalse);
      cubit.values['rental_period'] = 'custom';
      expect(cubit.valid('pricing'), isFalse);
      cubit.values['custom_months'] = '24';
      expect(cubit.valid('pricing'), isTrue);
      cubit.values.remove('negotiable');
      expect(cubit.valid('pricing'), isFalse);
    },
  );
  testWidgets(
    'rental duration updates the live calculator and unrelated fields keep its valid quote',
    (tester) async {
      final repo = CalculatorRepository();
      final cubit = ListingCubit(repo)
        ..values.addAll({
          'category': 'private_rental',
          'area_id': 'maadi',
          'price': '12000',
          'rental_period': 'one_year',
          'deposit': '0',
        });
      addTearDown(cubit.close);
      final readiness = <bool>[];
      await tester.pumpWidget(
        financialApp(
          ListingPricingStep(
            cubit: cubit,
            repository: repo,
            onReadyChanged: readiness.add,
          ),
        ),
      );
      await calculate(tester);
      expect(find.text('12,250.00 EGP'), findsOneWidget);
      expect(find.text('11,750.00 EGP'), findsOneWidget);
      await tap(tester, find.byKey(const Key('pricing-period')));
      await tester.tap(find.text('3 years').last);
      await tester.pumpAndSettle();
      await calculate(tester);
      expect(repo.quotes.last['rental_period'], 'three_years');
      expect(find.text('12,125.00 EGP'), findsOneWidget);
      expect(find.text('11,875.00 EGP'), findsOneWidget);
      final requests = repo.quotes.length;
      await tap(tester, find.byKey(const ValueKey('pricing-negotiable-false')));
      await tester.enterText(
        find.byKey(const ValueKey('pricing-deposit')),
        '1000',
      );
      await calculate(tester);
      expect(repo.quotes.length, requests);
      expect(readiness.last, isTrue);
    },
  );
  testWidgets(
    'sale price accepts Arabic digits and drops hidden rental fields',
    (tester) async {
      final repo = CalculatorRepository();
      final cubit = ListingCubit(repo)
        ..values.addAll({
          'category': 'sale_installments',
          'area_id': 'maadi',
          'rental_period': 'old_rent',
          'custom_months': '12',
        });
      addTearDown(cubit.close);
      await tester.pumpWidget(
        financialApp(
          ListingPricingStep(
            cubit: cubit,
            repository: repo,
            onReadyChanged: (_) {},
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('pricing-price')),
        '٢٠٠٠٠٠٠',
      );
      await calculate(tester);
      expect(repo.quotes.last['price'], '2000000');
      expect(repo.quotes.last.containsKey('rental_period'), isFalse);
      expect(find.text('2,010,000.00 EGP'), findsOneWidget);
      expect(find.text('1,990,000.00 EGP'), findsOneWidget);
      expect(find.text('20,000.00 EGP'), findsOneWidget);
      expect(find.text('1%'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pricing-down_payment')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pricing-period')), findsNothing);
    },
  );
  testWidgets(
    'failed calculation can retry and clearing price removes its amounts/readiness',
    (tester) async {
      final repo = CalculatorRepository()..fail = true;
      final cubit = ListingCubit(repo)
        ..values.addAll({
          'category': 'sale_cash',
          'area_id': 'maadi',
          'price': '2000000',
        });
      addTearDown(cubit.close);
      final readiness = <bool>[];
      await tester.pumpWidget(
        financialApp(
          ListingPricingStep(
            cubit: cubit,
            repository: repo,
            onReadyChanged: readiness.add,
          ),
        ),
      );
      await calculate(tester);
      expect(readiness.last, isFalse);
      repo.fail = false;
      await tap(tester, find.text('Retry calculation'));
      await calculate(tester);
      expect(readiness.last, isTrue);
      await tester.enterText(find.byKey(const ValueKey('pricing-price')), '');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calculatorOwner')), findsNothing);
      expect(readiness.last, isFalse);
    },
  );
  testWidgets(
    'old quote cannot overwrite a newer result, and draft identity is forwarded',
    (tester) async {
      final old = Completer<Map<String, dynamic>>(),
          fresh = Completer<Map<String, dynamic>>();
      final repo = CalculatorRepository()
        ..response = (values) =>
            values['price'] == '2000000' ? old.future : fresh.future;
      final values = ValueNotifier<Map<String, dynamic>>({
        'category': 'sale_cash',
        'area_id': 'maadi',
        'price': '2000000',
      });
      addTearDown(values.dispose);
      await tester.pumpWidget(
        financialApp(
          ValueListenableBuilder(
            valueListenable: values,
            builder: (context, data, _) => PriceQuotePanel(
              repository: repo,
              values: data,
              propertyId: 'saved-draft',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      values.value = {...values.value, 'price': '1900000'};
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      fresh.complete({
        ...saleQuote,
        'display_price': '1910000.00',
        'seller_net': '1890000.00',
      });
      await tester.pumpAndSettle();
      old.complete(saleQuote);
      await tester.pumpAndSettle();
      expect(find.text('1,910,000.00 EGP'), findsOneWidget);
      expect(find.text('2,010,000.00 EGP'), findsNothing);
      expect(
        repo.quotes.every((q) => q['property_id'] == 'saved-draft'),
        isTrue,
      );
    },
  );
  for (final category in ['shared_rental', 'private_rental']) {
    testWidgets(
      'calculator $category remains clear at narrow Arabic dark width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = CalculatorRepository()
          ..response = (_) async =>
              category == 'shared_rental' ? sharedQuote : oldRentQuote;
        final cubit = ListingCubit(repo)
          ..values.addAll({
            'category': category,
            'area_id': 'maadi',
            'price': category == 'shared_rental' ? '3000' : '10000',
            'rental_period': category == 'shared_rental'
                ? 'one_year'
                : 'old_rent',
            'total_beds': '4',
          });
        addTearDown(cubit.close);
        await tester.pumpWidget(
          financialApp(
            ListingPricingStep(
              cubit: cubit,
              repository: repo,
              onReadyChanged: (_) {},
            ),
            language: 'ar',
            dark: true,
          ),
        );
        await calculate(tester);
        if (category == 'shared_rental') {
          expect(repo.quotes.last['total_beds'], 4);
          expect(find.textContaining('750.00 ج.م'), findsOneWidget);
        } else {
          expect(find.textContaining('12'), findsWidgets);
          expect(find.textContaining('لا التزام مالي'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
