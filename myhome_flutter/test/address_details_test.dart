import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/core/widgets/choice_artwork.dart';
import 'package:myhome_flutter/core/widgets/selection_tile.dart';
import 'package:myhome_flutter/features/auth/domain/auth_repository.dart';
import 'package:myhome_flutter/features/chat/domain/chat_repository.dart';
import 'package:myhome_flutter/features/chat/presentation/contact_pages.dart';
import 'package:myhome_flutter/features/chat/presentation/chat_page.dart';
import 'package:myhome_flutter/features/properties/domain/structured_address.dart';
import 'package:myhome_flutter/features/properties/presentation/property_details_page.dart';
import 'package:myhome_flutter/features/properties/presentation/property_features_grid.dart';
import 'package:myhome_flutter/features/sales/presentation/financial_card.dart';
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'widget_test.dart' show launch;
import 'visual_listing_test.dart' show openListing, nextStep, completeAddress;
import 'onboarding_pricing_test.dart' show tap;

class DetailRepository extends FakePropertyRepository {
  @override
  Future<Map<String, dynamic>> details(String id) async => {
    ...await super.details(id),
    'category': 'sale_cash',
    'property_kind': 'apartment',
    'price': '2010000',
    'financial': {
      'original_price': '2000000',
      'buyer_fee': '10000',
      'seller_fee': '10000',
    },
    'full_address_en': '7 Test street, Maadi, Cairo, Floor 4, Apartment 12',
    'full_address_ar': '7 شارع الاختبار، المعادي، القاهرة، الدور 4، شقة رقم 12',
  };
  @override
  Future<Map<String, dynamic>> interested(String id, {String? before}) async =>
      {
        'items': [
          {'id': 'buyer', 'name': 'Interested person'},
        ],
        'next_cursor': null,
      };
}

class PropertyChatFake extends Fake implements ChatRepository {
  final targets = <String>[];
  @override
  Future<String> openProperty(String id, {String? seekerId}) async {
    targets.add('$id:${seekerId ?? 'self'}');
    return 'conversation';
  }

  @override
  Future<ChatBatch> read(String id, {int? before, int? after}) async =>
      const ChatBatch([], null);
}

void main() {
  test(
    'structured address keeps all four parts and preserves ground floor zero',
    () {
      final values = {
        'street_address': 'Test street',
        'building_number': '7',
        'floor_number': 0,
        'unit_number': '12',
      };
      expect(
        structuredAddress(values, 'Maadi, Cairo', arabic: false),
        '7 Test street, Maadi, Cairo, Floor 0, Apartment 12',
      );
      expect(
        structuredAddress(values, 'المعادي، القاهرة', arabic: true),
        contains('الدور الأرضي'),
      );
    },
  );
  testWidgets(
    'location requires street, building, floor and unit before advancing',
    (tester) async {
      await openListing(tester);
      await tap(
        tester,
        find.byKey(const ValueKey('choice-category-sale_cash')),
      );
      await nextStep(tester);
      await tap(tester, find.byKey(const ValueKey('property-kind-apartment')));
      await nextStep(tester);
      await tap(tester, find.byKey(const Key('listingGovernorate')));
      await tap(tester, find.text('Cairo').last);
      await tap(tester, find.byKey(const Key('listingAreaPicker')));
      await tap(tester, find.byKey(const ValueKey('location-option-maadi')));
      expect(find.byType(SwitchListTile), findsNothing);
      await nextStep(tester);
      expect(
        find.byKey(const ValueKey('address-street_address')),
        findsOneWidget,
      );
      await completeAddress(tester);
      expect(find.textContaining('7 Test street'), findsWidgets);
      await nextStep(tester);
      expect(find.byKey(const ValueKey('area-115')), findsOneWidget);
    },
  );

  for (final language in ['ar', 'en']) {
    testWidgets(
      'details show one final price, captioned pictures and independent contact $language',
      (tester) async {
        final repo = DetailRepository();
        final chat = PropertyChatFake();
        await launch(
          tester,
          FakeAuthRepository()
            ..restored = const Account(
              id: 'buyer',
              name: 'Buyer',
              email: 'buyer@example.com',
              role: 'user',
              ownerVerified: false,
              intents: ['buyer_cash'],
              activeIntent: 'buyer_cash',
            ),
          properties: repo,
          chat: chat,
          language: language,
          size: const Size(390, 1000),
        );
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => RepositoryProvider<ChatRepository>.value(
              value: chat,
              child: PropertyDetailsPage(id: 'p1', repository: repo),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FinancialCard), findsNothing);
        expect(find.byKey(const Key('propertyFinalPrice')), findsOneWidget);
        expect(find.text('10000'), findsNothing);
        expect(find.byKey(const Key('buyProperty')), findsOneWidget);
        final grid = find.byType(PropertyFeaturesGrid);
        expect(
          find.descendant(of: grid, matching: find.byType(Icon)),
          findsWidgets,
        );
        expect(
          find.descendant(of: grid, matching: find.byType(ChoiceArtwork)),
          findsNothing,
        );
        await tap(tester, find.byKey(const Key('contactOwner')));
        expect(find.byType(ChatPage), findsOneWidget);
        expect(chat.targets, ['p1:self']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('picture selection caption is below the image at desktop width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: SelectionTile(
              label: 'Apartment',
              artwork: 'apartment',
              selected: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(ChoiceArtwork)).dy,
      lessThan(tester.getTopLeft(find.text('Apartment')).dy),
    );
    expect(find.byType(Checkbox), findsNothing);
  });
  testWidgets(
    'owner can open the saved-account property chat from the interest list',
    (tester) async {
      final repo = DetailRepository(), chat = PropertyChatFake();
      await launch(
        tester,
        FakeAuthRepository()..restored = account,
        properties: repo,
        chat: chat,
      );
      Navigator.of(tester.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(
          builder: (_) => RepositoryProvider<ChatRepository>.value(
            value: chat,
            child: const ContactListPage(propertyId: 'p1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Interested person'), findsOneWidget);
      await tap(tester, find.byTooltip('Message'));
      expect(chat.targets, ['p1:buyer']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
