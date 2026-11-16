import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhome_flutter/features/chat/domain/chat_repository.dart';
import 'package:myhome_flutter/features/chat/presentation/chat_page.dart';
import 'package:myhome_flutter/features/chat/presentation/conversation_list.dart';
import 'package:myhome_flutter/features/properties/domain/property_repository.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_cubit.dart';
import 'package:myhome_flutter/features/properties/presentation/listing_optional_features.dart';
import 'package:myhome_flutter/features/properties/presentation/property_details_page.dart';
import 'package:myhome_flutter/features/properties/presentation/property_gallery.dart';
import 'package:myhome_flutter/features/properties/presentation/similar_properties.dart';
import 'address_details_test.dart' show DetailRepository;
import 'fake_property_repository.dart';
import 'fakes.dart';
import 'widget_test.dart' show launch;

class ExperienceRepository extends DetailRepository {
  @override
  Future<List<int>> privateImage(String id) async => (await rootBundle.load(
    'assets/branding/app-icon.png',
  )).buffer.asUint8List();
  @override
  Future<Map<String, dynamic>> details(String id) async => {
    ...await super.details(id),
    'title': 'Apartment $id',
    'owner_name': 'Demo owner',
    'ownerVerified': true,
    'compound': true,
    'security': false,
    'internet': null,
    'garage': true,
    'orientation': 'north',
    'kitchen_type': 'american_kitchen',
    'finishing': 'ultra_super_lux',
  };
  @override
  Future<List<PropertySummary>> similar(String id) async => [
    PropertySummary(
      id: 'recommended',
      title: 'Recommended apartment',
      category: 'sale_cash',
      price: '2010000',
      areaM2: '115',
      locationAr: 'المعادي',
      locationEn: 'Maadi',
      negotiable: false,
      bedrooms: 2,
      bathrooms: 1,
      capacity: null,
    ),
  ];
}

class ExperienceChat extends Fake implements ChatRepository {
  final sent = <String>[];
  @override
  Future<String> openProperty(String id, {String? seekerId}) async => 'chat';
  @override
  Future<Map<String, dynamic>> metadata(String id) async => {
    'name': 'Demo owner',
    'kind': 'property',
    'owner_verified': true,
    'property': {
      'id': 'p1',
      'title': 'Apartment p1',
      'price': '2010000',
      'category': 'sale_cash',
    },
  };
  @override
  Future<Map<String, dynamic>> inbox({String? before}) async => {
    'items': [
      {
        'id': 'chat',
        'name': 'Demo owner',
        'title': 'Apartment p1',
        'last_message': 'Ready for a viewing',
        'property': {
          'id': 'p1',
          'title': 'Apartment p1',
          'category': 'sale_cash',
          'price': '2010000',
        },
      },
    ],
    'next_cursor': null,
  };
  @override
  Future<ChatBatch> read(String id, {int? before, int? after}) async =>
      ChatBatch(
        after == null
            ? [
                ChatMessage(
                  1,
                  'Ready for a viewing',
                  'Owner',
                  false,
                  createdAt: DateTime.utc(2026, 11, 16, 10, 34),
                ),
              ]
            : [],
        null,
      );
  @override
  Future<ChatMessage> send(String id, String text) async {
    sent.add(text);
    throw const ChatFailure('CONTACT_DETAILS_BLOCKED');
  }
}

void main() {
  test(
    'optional features can be omitted or explicitly false; ultra furnishing is valid',
    () {
      final cubit = ListingCubit(FakePropertyRepository());
      cubit.values.addAll({
        'category': 'sale_cash',
        'finishing': 'ultra_super_lux',
        'furnished': true,
        'garage': false,
        'orientation': 'north',
        'kitchen_type': 'american_kitchen',
      });
      expect(cubit.valid('finishing'), isTrue);
      expect(cubit.payload()['garage'], isFalse);
      expect(cubit.payload().containsKey('internet'), isFalse);
      expect(cubit.payload()['orientation'], 'north');
      cubit.values['finishing'] = 'red_brick';
      expect(cubit.payload().containsKey('furnished'), isFalse);
      cubit.close();
    },
  );
  testWidgets(
    'optional choices preserve unspecified, false and true independently',
    (tester) async {
      final values = <String, dynamic>{};
      await launch(tester, FakeAuthRepository());
      Navigator.of(tester.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: ListingOptionalFeatures(
                  values: values,
                  onChanged: (key, value) =>
                      setState(() => values[key] = value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> choose(String key) async {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await choose('optional-compound-true');
      await choose('optional-garage-false');
      expect(values['compound'], true);
      expect(values['garage'], false);
      expect(values.containsKey('internet'), false);
      await choose('optional-garage-unspecified');
      expect(values['garage'], isNull);
      expect(tester.takeException(), isNull);
    },
  );
  for (final spec in [
    (language: 'ar', size: const Size(320, 1000)),
    (language: 'en', size: const Size(1440, 1100)),
  ]) {
    testWidgets(
      'responsive gallery opens all protected photos ${spec.language}',
      (tester) async {
        final repo = ExperienceRepository();
        await launch(
          tester,
          FakeAuthRepository(),
          properties: repo,
          language: spec.language,
          size: spec.size,
        );
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: PropertyGallery(
                photos: const ['1', '2', '3', '4', '5', '6'],
                category: 'sale_cash',
                repository: repo,
                private: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('openPropertyGallery')));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.textContaining('1 / 6'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.byTooltip(
            MaterialLocalizations.of(
              tester.element(find.byType(InteractiveViewer).first),
            ).nextPageTooltip,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('2 / 6'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'chat shows actual property context and quick drafts; moderation preserves input ${spec.language}',
      (tester) async {
        final chat = ExperienceChat();
        await launch(
          tester,
          FakeAuthRepository()..restored = account,
          properties: ExperienceRepository(),
          chat: chat,
          language: spec.language,
          size: spec.size,
        );
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) => const ChatPage(propertyId: 'p1'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Apartment p1'), findsWidgets);
        expect(
          find.byType(ConversationList),
          spec.size.width > 1000 ? findsOneWidget : findsNothing,
        );
        await tester.tap(
          find.text(spec.language == 'ar' ? 'رسائل سريعة' : 'Quick messages'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('quickViewing')));
        expect(chat.sent, isEmpty);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('chatInput')))
              .controller!
              .text,
          isNotEmpty,
        );
        await tester.enterText(
          find.byKey(const Key('chatInput')),
          '01012345678',
        );
        await tester.tap(find.byKey(const Key('sendMessage')));
        await tester.pumpAndSettle();
        expect(chat.sent, ['01012345678']);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('chatInput')))
              .controller!
              .text,
          '01012345678',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('similar recommendations open real listing details', (
    tester,
  ) async {
    final repo = ExperienceRepository();
    await launch(
      tester,
      FakeAuthRepository()..restored = account,
      properties: repo,
    );
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SimilarProperties(
            propertyId: 'p1',
            repository: repo,
            onDetails: (id) => Navigator.push(
              tester.element(find.byType(SimilarProperties)),
              MaterialPageRoute<void>(
                builder: (_) => PropertyDetailsPage(id: id, repository: repo),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recommended apartment'));
    await tester.pumpAndSettle();
    expect(find.text('Apartment recommended'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
