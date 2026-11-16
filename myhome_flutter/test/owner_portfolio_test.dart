import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/properties/domain/property_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/owner_portfolio_cubit.dart';
import 'package:myhome_flutter/features/properties/presentation/owner_portfolio_page.dart';
import 'package:myhome_flutter/features/properties/presentation/price_quote_panel.dart';
import 'package:myhome_flutter/features/properties/presentation/property_list_page.dart';
import 'package:myhome_flutter/features/properties/presentation/property_card.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'widget_test.dart' show launch;

PropertySummary home(String id, {String availability = 'active'}) =>
    PropertySummary(
      id: id,
      title: 'Apartment $id',
      category: 'sale_cash',
      price: '1000000',
      areaM2: '100',
      locationAr: 'المعادي',
      locationEn: 'Maadi',
      negotiable: false,
      bedrooms: 2,
      bathrooms: 1,
      capacity: 4,
      availability: availability,
      visitorCount: 24,
      savedCount: 5,
    );

class PortfolioRepository extends FakePropertyRepository {
  final requests = <Map<String, String?>>[];
  final changed = <String>[];
  final interestedRequests = <String>[];
  bool failMore = false;
  String visibility = 'active';
  @override
  Future<Map<String, dynamic>> interested(String id, {String? before}) async {
    interestedRequests.add(id);
    return {
      'items': [
        {'id': 'buyer', 'name': 'Interested person'},
      ],
      'next_cursor': null,
    };
  }

  @override
  Future<List<PortfolioCount>> portfolio() async => const [
    PortfolioCount('sale', 5, 5, 0, 1, 0),
    PortfolioCount('private_rental', 3, 2, 1, 1, 0),
    PortfolioCount('shared_rental', 1, 1, 0, 0, 0),
  ];
  @override
  Future<OwnerPage> ownerPage(
    String group, {
    String scope = 'current',
    String query = '',
    String availability = 'all',
    String? cursor,
  }) async {
    requests.add({'scope': scope, 'q': query, 'cursor': cursor});
    if (cursor != null && failMore) {
      throw const PropertyException('NETWORK_ERROR');
    }
    return cursor == null
        ? OwnerPage(
            [home('1', availability: visibility), home('2'), home('3')],
            5,
            'next',
          )
        : OwnerPage([home('4'), home('5')], 5, null);
  }

  @override
  Future<void> changeAvailability(String id, String availability) async {
    changed.add('$id:$availability');
    visibility = availability;
  }

  @override
  Future<Map<String, dynamic>> priceQuote(Map<String, dynamic> values) async =>
      {
        'requires_agreement': false,
        'enabled': false,
        'owner_price': '1000000',
        'platform_fee': '10000',
        'display_price': '1010000',
        'price_basis': 'sale',
      };
}

void main() {
  for (final spec in [
    (language: 'ar', size: const Size(320, 844)),
    (language: 'en', size: const Size(1440, 1100)),
  ]) {
    testWidgets(
      'owner eye/save counters stay inside the card and open savers in ${spec.language}',
      (tester) async {
        final repo = PortfolioRepository();
        final openedDetails = <String>[];
        await launch(
          tester,
          FakeAuthRepository()..restored = account,
          properties: repo,
          language: spec.language,
          size: spec.size,
        );
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => OwnerPortfolioPage(
              repository: repo,
              onDetails: openedDetails.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final property = find.byWidgetPredicate(
          (widget) => widget is PropertyCard && widget.property.id == '1',
        );
        final card = find.descendant(of: property, matching: find.byType(Card));
        final bookmark = find.byKey(const ValueKey('interested-1'));
        await tester.ensureVisible(bookmark);
        await tester.pumpAndSettle();
        await tester.ensureVisible(bookmark);
        for (final icon in [Icons.visibility_outlined, Icons.bookmark_border]) {
          final counterIcon = find.descendant(
            of: card,
            matching: find.byIcon(icon),
          );
          expect(counterIcon, findsOneWidget);
          expect(
            tester.getRect(card).contains(tester.getCenter(counterIcon)),
            isTrue,
          );
        }
        for (final number in ['24', '5']) {
          expect(
            find.descendant(of: card, matching: find.text(number)),
            findsOneWidget,
          );
        }
        expect(find.textContaining('عدد الزوار:'), findsNothing);
        expect(find.textContaining('Unique visitors:'), findsNothing);
        expect(tester.getSize(bookmark).height, greaterThanOrEqualTo(48));
        await tester.tap(bookmark);
        await tester.pumpAndSettle();
        expect(repo.interestedRequests, ['1']);
        expect(find.text('Interested person'), findsOneWidget);
        expect(openedDetails, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('public property cards do not show owner engagement counters', (
    tester,
  ) async {
    final repo = PortfolioRepository()..items = [home('public')];
    await launch(tester, FakeAuthRepository(), properties: repo);
    final card = find.byType(PropertyCard).first;
    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.visibility_outlined),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.bookmark_border)),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('interested-public')), findsNothing);
  });
  testWidgets(
    'saved unavailable cards show status and saved-price labels without property images',
    (tester) async {
      final repo = FakePropertyRepository()
        ..items = [
          for (final status in ['paused', 'sold', 'rented'])
            PropertySummary(
              id: status,
              title: 'Saved $status',
              category: status == 'sold' ? 'sale_cash' : 'private_rental',
              price: '5000',
              areaM2: '0',
              locationAr: '',
              locationEn: '',
              negotiable: false,
              bedrooms: 0,
              bathrooms: 0,
              capacity: 0,
              availability: status,
              unavailable: true,
            ),
        ];
      await launch(tester, FakeAuthRepository(), properties: repo);
      Navigator.of(tester.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(
          builder: (_) => PropertyListPage(repository: repo, onDetails: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Currently paused'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
      expect(find.byIcon(Icons.home_work_outlined), findsNothing);
      expect(find.text('Price when saved'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'three-item pages append, preserve data on failure and retry without duplicates',
    () async {
      final repo = PortfolioRepository();
      final cubit = OwnerListingsCubit(repo, 'sale');
      await cubit.search();
      expect(cubit.state.items.length, 3);
      expect(repo.requests.length, 1);
      repo.failMore = true;
      await cubit.more();
      expect(cubit.state.items.length, 3);
      expect(cubit.state.moreFailed, true);
      repo.failMore = false;
      await cubit.more();
      expect(cubit.state.items.map((p) => p.id), ['1', '2', '3', '4', '5']);
      expect(cubit.state.cursor, isNull);
      await cubit.more();
      expect(repo.requests.length, 3);
      await cubit.close();
    },
  );
  test('older owner search cannot overwrite a newer query', () async {
    final old = Completer<OwnerPage>(), fresh = Completer<OwnerPage>();
    final repo = _DeferredOwnerRepository(old, fresh);
    final cubit = OwnerListingsCubit(repo, 'sale');
    final a = cubit.search(text: 'old');
    final b = cubit.search(text: 'fresh');
    fresh.complete(OwnerPage([home('fresh')], 1, null));
    await b;
    old.complete(OwnerPage([home('old')], 1, null));
    await a;
    expect(cubit.state.items.single.id, 'fresh');
    await cubit.close();
  });
  testWidgets(
    'Arabic owner dashboard drills into sale, pauses a listing and searches at 320px',
    (tester) async {
      final repo = PortfolioRepository();
      await launch(
        tester,
        FakeAuthRepository()..restored = account,
        properties: repo,
        language: 'ar',
        size: const Size(320, 844),
      );
      Navigator.of(tester.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              OwnerPortfolioPage(repository: repo, onDetails: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.requests.length, 1);
      await tester.ensureVisible(find.byKey(const ValueKey('visibility-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('visibility-1')));
      await tester.tap(find.byKey(const ValueKey('visibility-1')));
      await tester.pumpAndSettle();
      expect(repo.changed, ['1:paused']);
      await tester.enterText(
        find.byKey(const Key('ownerQuickSearch')),
        'Apartment 2',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(repo.requests.last['q'], 'Apartment 2');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('fee preview clearly stays a proposal until policy activation', (
    tester,
  ) async {
    final repo = PortfolioRepository();
    await launch(tester, FakeAuthRepository(), properties: repo);
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: PriceQuotePanel(
            repository: repo,
            values: {
              'category': 'sale_cash',
              'price': '1000000',
              'area_id': 'maadi',
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Proposed preview only'), findsOneWidget);
    expect(find.textContaining('1010000'), findsOneWidget);
  });
}

class _DeferredOwnerRepository extends FakePropertyRepository {
  final Completer<OwnerPage> old, fresh;
  _DeferredOwnerRepository(this.old, this.fresh);
  @override
  Future<OwnerPage> ownerPage(
    String group, {
    String scope = 'current',
    String query = '',
    String availability = 'all',
    String? cursor,
  }) => query == 'old' ? old.future : fresh.future;
}
